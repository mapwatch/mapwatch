module Mapwatch exposing
    ( Model
    , Msg(..)
    , OkModel
    , ReadyState(..)
    , init
    , initModel
    , isReady
    , lastUpdatedAt
    , ready
    , subscriptions
    , tick
    , update
    , updateOk
    )

import Duration exposing (Millis)
import Json.Decode as D
import Mapwatch.Datamine as Datamine exposing (Datamine)
import Mapwatch.Instance as Instance
import Mapwatch.LogLine as LogLine
import Mapwatch.Run as Run
import Mapwatch.Visit as Visit
import Maybe.Extra
import Ports
import Readline
import Settings exposing (Settings)
import Time exposing (Posix)
import TimedReadline exposing (TimedReadline)


type alias Model =
    Result String OkModel


type alias OkModel =
    { datamine : Datamine
    , history : Maybe TimedReadline
    , instance : Maybe Instance.State
    , runState : Run.State
    , runs : List Run.Run
    , readline : Maybe TimedReadline
    , tz : Maybe Time.Zone
    }


type Msg
    = LogSlice { date : Int, position : Int, length : Int, value : String }
    | LogChanged { date : Int, size : Int, oldSize : Int }
    | LogOpened { date : Int, size : Int }


createModel : Maybe Time.Zone -> Datamine -> OkModel
createModel tz datamine =
    { datamine = datamine
    , instance = Nothing
    , runState = Run.Empty
    , readline = Nothing
    , history = Nothing
    , runs = []
    , tz = tz
    }


initModel : Maybe Time.Zone -> D.Value -> Model
initModel tz =
    D.decodeValue Datamine.decoder
        >> Result.mapError D.errorToString
        >> Result.map (createModel tz)


init : Maybe Time.Zone -> D.Value -> ( Model, Cmd Msg )
init tz datamineJson =
    ( initModel tz datamineJson, Cmd.none )


updateLine : Settings -> LogLine.Line -> ( OkModel, List (Cmd Msg) ) -> ( OkModel, List (Cmd Msg) )
updateLine settings line ( model, cmds0 ) =
    let
        instance =
            Instance.initOrUpdate model.datamine line model.instance

        visit =
            Visit.tryInit model.instance instance

        ( runState, lastRun ) =
            Run.update instance visit model.runState
                |> Tuple.mapFirst (Run.updateNPCText line)

        runs =
            case lastRun of
                Just lastRun_ ->
                    lastRun_ :: model.runs

                Nothing ->
                    model.runs

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


tick : Posix -> OkModel -> OkModel
tick t model =
    case model.instance of
        Nothing ->
            -- no loglines processed yet, no need to tick
            model

        Just instance ->
            let
                ( runState, lastRun ) =
                    Run.tick t instance model.runState

                runs =
                    case lastRun of
                        Just lastRun_ ->
                            lastRun_ :: model.runs

                        Nothing ->
                            model.runs
            in
            { model | runState = runState, runs = runs }


update : Settings -> Msg -> Model -> ( Model, Cmd Msg )
update settings msg rmodel =
    case rmodel of
        Err err ->
            ( rmodel, Cmd.none )

        Ok model ->
            updateOk settings msg model
                |> Tuple.mapFirst Ok


updateOk : Settings -> Msg -> OkModel -> ( OkModel, Cmd Msg )
updateOk settings msg model =
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


ready : OkModel -> ReadyState
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


isReady : OkModel -> Bool
isReady =
    .history >> Maybe.Extra.isJust


lastUpdatedAt : OkModel -> Maybe Posix
lastUpdatedAt model =
    [ model.instance |> Maybe.map .joinedAt
    , model.runState |> Run.stateLastUpdatedAt
    , model.runs |> List.head |> Maybe.map (\r -> r.last.leftAt)
    ]
        |> List.filterMap identity
        |> List.head
