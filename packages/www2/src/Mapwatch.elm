module Mapwatch exposing
    ( Model
    , Msg(..)
    , ReadyState(..)
    , filteredLogSlice
    , fromLogSlice
    , init
    , initModel
    , isReady
    , lastUpdatedAt
    , ready
    , subscriptions
    , tick
    , update
    )

import Bytes.Encode
import Dict exposing (Dict)
import Duration exposing (Millis)
import Json.Decode as D
import Mapwatch.Datamine as Datamine exposing (Datamine)
import Mapwatch.Instance as Instance
import Mapwatch.LogLine as LogLine
import Mapwatch.MapRun as MapRun exposing (MapRun)
import Mapwatch.RawMapRun as RawMapRun exposing (RawMapRun)
import Mapwatch.Visit as Visit
import Maybe.Extra
import Ports
import Readline
import Regex exposing (Regex)
import Result.Extra
import Settings exposing (Settings)
import Time exposing (Posix)
import TimedReadline exposing (TimedReadline)


type alias Model =
    { datamine : Datamine
    , history : Maybe TimedReadline
    , instance : Maybe Instance.State
    , runState : RawMapRun.State
    , runs : List MapRun
    , readline : Maybe TimedReadline
    , tz : Maybe Time.Zone
    }


type Msg
    = LogSlice { date : Int, position : Int, length : Int, value : String }
    | LogChanged { date : Int, size : Int, oldSize : Int }
    | LogOpened { date : Int, size : Int }


createModel : Maybe Time.Zone -> Datamine -> Model
createModel tz datamine =
    { datamine = datamine
    , instance = Nothing
    , runState = Nothing
    , readline = Nothing
    , history = Nothing
    , runs = []
    , tz = tz
    }


initModel : Maybe Time.Zone -> D.Value -> Result String Model
initModel tz =
    D.decodeValue Datamine.decoder
        >> Result.mapError D.errorToString
        >> Result.map (createModel tz)


fromLogSlice : Maybe Time.Zone -> Datamine -> Settings -> Int -> String -> Model
fromLogSlice tz datamine settings position log =
    -- for the `/logslice` page. Turn a string into a map run, and relevant log lines
    let
        size =
            Bytes.Encode.getStringWidth log

        model0 =
            createModel tz datamine
    in
    -- logOpened with a fudged start position, to keep links identical to the history screen
    { model0 | readline = TimedReadline.create { now = Time.millisToPosix 0, start = position, end = position + size } |> Just }
        |> update settings (LogSlice { date = 0, position = position, length = size, value = log ++ "\n" })
        |> Tuple.first


filteredLogSlice : Time.Zone -> Datamine -> Settings -> Int -> String -> String
filteredLogSlice tz datamine settings position log =
    -- step 1: filter all lines that mean something to mapwatch; all non-parse-errors
    Readline.create { start = 0, end = Bytes.Encode.getStringWidth log + 1 }
        |> Readline.read 0 (log ++ "\n")
        |> Tuple.first
        |> List.filter (LogLine.parse datamine tz >> Result.Extra.isOk)
        |> List.map Tuple.second
        -- step 2: remove the gibberish between the date and the message
        |> List.map
            (\line ->
                case line |> String.indexes "]" |> List.head of
                    Nothing ->
                        line

                    Just end ->
                        String.left LogLine.dateLength line
                            ++ String.dropLeft end line
            )
        -- step 3: filter IP addresses
        |> List.foldl
            (\line ( count, seens, accum ) ->
                line
                    |> filterIp 0 count seens
                    |> (\( count2, seens2, line2 ) -> ( count2, seens2, line2 :: accum ))
            )
            ( 0, Dict.empty, [] )
        |> (\( c, s, a ) -> a)
        |> List.reverse
        -- finally, join the results into one string
        |> String.join "\n"


ipRegex : Regex
ipRegex =
    Regex.fromString "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}" |> Maybe.withDefault Regex.never


filterIp : Int -> Int -> Dict String String -> String -> ( Int, Dict String String, String )
filterIp index count seens line =
    case line |> String.dropLeft index |> Regex.findAtMost 1 ipRegex |> List.head of
        Nothing ->
            ( count, seens, line )

        Just match ->
            let
                endIndex =
                    index + match.index + String.length match.match
            in
            case Dict.get match.match seens of
                Nothing ->
                    let
                        replace =
                            "999.999.999." ++ String.fromInt count
                    in
                    String.left (index + match.index) line
                        ++ replace
                        ++ String.dropLeft endIndex line
                        |> filterIp endIndex (count + 1) (seens |> Dict.insert match.match replace)

                Just replace ->
                    String.left (index + match.index) line
                        ++ replace
                        ++ String.dropLeft endIndex line
                        |> filterIp endIndex count seens


init : Maybe Time.Zone -> D.Value -> ( Result String Model, Cmd Msg )
init tz datamineJson =
    ( initModel tz datamineJson, Cmd.none )


updateLine : Settings -> LogLine.Line -> ( Model, List (Cmd Msg) ) -> ( Model, List (Cmd Msg) )
updateLine settings line ( model, cmds0 ) =
    let
        instance =
            Instance.initOrUpdate model.datamine line model.instance

        visit =
            Visit.tryInit model.instance instance <| LogLine.positionEnd line

        ( runState, lastRun ) =
            RawMapRun.update instance visit model.runState
                |> Tuple.mapBoth (RawMapRun.updateNPCText line instance.val) (Maybe.map (MapRun.fromRaw model.datamine))

        runs : List MapRun
        runs =
            Maybe.Extra.unwrap model.runs (\r -> r :: model.runs) lastRun

        cmds =
            case model.instance of
                Nothing ->
                    cmds0

                Just i ->
                    if instance.joinedAt == i.joinedAt then
                        cmds0

                    else
                        Ports.sendJoinInstance settings (Maybe.Extra.isJust model.history) instance.joinedAt instance.val visit runState lastRun
                            :: cmds0
    in
    ( { model
        | instance = Just instance

        -- , visits = Maybe.Extra.unwrap model.visits (\v -> v :: model.visits) visit
        , runState = runState
        , runs = runs
      }
    , cmds
    )


tick : Posix -> Model -> Model
tick t model =
    case model.instance of
        Nothing ->
            -- no loglines processed yet, no need to tick
            model

        Just instance ->
            let
                ( runState, lastRun ) =
                    RawMapRun.tick t instance model.runState
                        |> Tuple.mapSecond (Maybe.map (MapRun.fromRaw model.datamine))

                runs =
                    Maybe.Extra.unwrap model.runs (\r -> r :: model.runs) lastRun
            in
            { model | runState = runState, runs = runs }


update : Settings -> Msg -> Model -> ( Model, Cmd Msg )
update settings msg model =
    case msg of
        LogOpened { date, size } ->
            case model.readline of
                Just _ ->
                    ( model, Cmd.none )

                Nothing ->
                    let
                        readline =
                            TimedReadline.create { now = Time.millisToPosix date, start = 0, end = size }
                    in
                    ( { model | readline = Just readline }
                    , readline.val |> Readline.next |> Maybe.Extra.unwrap Cmd.none Ports.logSliceReq
                    )

        LogSlice { date, position, length, value } ->
            case model.readline of
                Nothing ->
                    ( model, Cmd.none )

                Just r ->
                    let
                        ( lines, readline ) =
                            TimedReadline.read (Time.millisToPosix date) position value r

                        ( model1, cmds ) =
                            -- Log-parsing errors are ignored: lines we don't use, like chat or asset-loading, are incredibly common
                            lines
                                |> List.filterMap (LogLine.parse model.datamine (Maybe.withDefault Time.utc model.tz) >> Result.toMaybe)
                                |> List.foldl (updateLine settings) ( model, [] )
                    in
                    case Readline.next readline.val of
                        Nothing ->
                            case model1.history of
                                Nothing ->
                                    ( { model1 | readline = Just readline, history = Just readline }
                                    , Cmd.batch <| Ports.progressComplete settings { name = "history" } :: cmds
                                    )

                                Just _ ->
                                    ( { model1 | readline = Just readline }, Cmd.batch cmds )

                        Just next ->
                            ( { model1 | readline = Just readline }
                            , Cmd.batch <| Ports.logSliceReq next :: cmds
                            )

        LogChanged { date, size } ->
            case model.readline of
                Nothing ->
                    ( model, Cmd.none )

                Just readline0 ->
                    case TimedReadline.resize (Time.millisToPosix date) size readline0 of
                        Err err ->
                            ( model, Cmd.none )

                        Ok readline ->
                            ( { model | readline = Just readline }
                            , readline.val |> Readline.next |> Maybe.Extra.unwrap Cmd.none Ports.logSliceReq
                            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.logSlice LogSlice
        , Ports.logChanged LogChanged
        , Ports.logOpened LogOpened
        ]


type ReadyState
    = NotStarted
    | LoadingHistory TimedReadline.Progress
    | Ready TimedReadline.Progress


ready : Model -> ReadyState
ready m =
    case m.history of
        Just h ->
            TimedReadline.progress h |> Ready

        Nothing ->
            case m.readline of
                Nothing ->
                    NotStarted

                Just r ->
                    TimedReadline.progress r |> LoadingHistory


isReady : Model -> Bool
isReady =
    .history >> Maybe.Extra.isJust


lastUpdatedAt : Model -> Maybe Posix
lastUpdatedAt model =
    [ model.instance |> Maybe.map .joinedAt
    , model.runState |> Maybe.map RawMapRun.updatedAt
    , model.runs |> List.head |> Maybe.map .updatedAt
    ]
        |> List.filterMap identity
        |> List.head
