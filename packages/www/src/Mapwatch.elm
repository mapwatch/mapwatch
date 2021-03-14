module Mapwatch exposing
    ( Model
    , Msg(..)
    , ReadyState(..)
    , init
    , initModel
    , isReady
    , lastUpdatedAt
    , ready
    , subscriptions
    , tick
    , update
    )

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


init : Maybe Time.Zone -> D.Value -> ( Result String Model, Cmd Msg )
init tz datamineJson =
    ( initModel tz datamineJson, Cmd.none )


updateLine : Settings -> LogLine.Line -> ( Model, List (Cmd Msg) ) -> ( Model, List (Cmd Msg) )
updateLine settings line ( model, cmds0 ) =
    let
        instance =
            Instance.initOrUpdate model.datamine line model.instance

        visit =
            Visit.tryInit model.instance instance

        ( runState, lastRun ) =
            RawMapRun.update instance visit model.runState
                |> Tuple.mapBoth (RawMapRun.updateNPCText line) (Maybe.map (MapRun.fromRaw model.datamine))

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
                            TimedReadline.read (Time.millisToPosix date) value r

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
