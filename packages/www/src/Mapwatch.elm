module Mapwatch
    exposing
        ( Model
        , Msg(..)
        , Progress
        , init
        , initModel
        , update
        , subscriptions
        , progressPercent
        , isProgressDone
        , isReady
        , progressDuration
        )

import Set
import Date
import Time
import Maybe.Extra
import AnimationFrame
import Navigation
import Ports
import Mapwatch.LogLine as LogLine
import Mapwatch.Zone as Zone
import Mapwatch.Instance as Instance
import Mapwatch.Visit as Visit
import Mapwatch.Run as Run
import Mapwatch.Route as Route exposing (Route)


type alias Flags =
    { loadedAt : Float
    , tickOffset : Float
    , isBrowserSupported : Bool
    }


type alias Progress =
    Ports.Progress


type alias Config =
    { maxSize : Int }


type alias Model =
    { config : Config
    , flags : Flags
    , loadedAt : Date.Date
    , route : Route
    , progress : Maybe Progress
    , now : Date.Date
    , parseError : Maybe LogLine.ParseError
    , instance : Instance.State
    , runState : Run.State
    , runs : List Run.Run
    , lines : List String
    }


type Msg
    = Tick Time.Time
    | InputClientLogWithId String
    | InputMaxSize String
    | RecvLogLine String
    | RecvProgress Progress
    | Navigate Navigation.Location
    | RouteTo Route
    | MapsSearch Route.MapsParams
    | HistorySearch Route.HistoryParams


initModel : Flags -> Route -> Model
initModel flags route =
    let
        loadedAt =
            Date.fromTime flags.loadedAt
    in
        { config = { maxSize = 20 }
        , flags = flags
        , route = route
        , parseError = Nothing
        , progress = Nothing
        , loadedAt = loadedAt
        , now = loadedAt
        , instance = Instance.init
        , runState = Run.Empty
        , runs = []
        , lines = []
        }


init flags loc =
    ( initModel flags (Route.parse loc), Cmd.none )


updateLine : LogLine.Line -> Model -> ( Model, Cmd Msg )
updateLine line model =
    let
        instance =
            Instance.update line model.instance

        visit =
            Visit.tryInit model.instance instance

        ( runState, lastRun ) =
            Run.update instance visit model.runState

        runs =
            case lastRun of
                Just lastRun ->
                    lastRun :: model.runs

                Nothing ->
                    model.runs

        cmd =
            if instance.joinedAt == model.instance.joinedAt then
                Cmd.none
            else
                Ports.sendJoinInstance (Instance.unsafeJoinedAt instance) instance.val visit lastRun
    in
        ( { model
            | instance = instance

            -- , visits = Maybe.Extra.unwrap model.visits (\v -> v :: model.visits) visit
            , runState = runState
            , runs = runs
          }
        , cmd
        )


updateRawLine : String -> Model -> Model
updateRawLine raw model =
    -- *Only when debugging*, save all raw loglines.
    case model.route of
        Route.DebugDumpLines ->
            { model | lines = raw :: model.lines }

        _ ->
            model


applyTimeOffset : Model -> Time.Time -> Date.Date
applyTimeOffset model t0 =
    Date.fromTime <| t0 - model.flags.tickOffset


tick : Time.Time -> Model -> Model
tick t0 model =
    let
        t =
            applyTimeOffset model t0

        ( runState, lastRun ) =
            Run.tick t model.instance model.runState

        runs =
            case lastRun of
                Just lastRun ->
                    lastRun :: model.runs

                Nothing ->
                    model.runs
    in
        { model | now = t, runState = runState, runs = runs }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ config } as model) =
    case msg of
        Tick t ->
            if Maybe.Extra.unwrap False isProgressDone model.progress then
                ( tick t model, Cmd.none )
            else
                ( { model | now = applyTimeOffset model t }, Cmd.none )

        Navigate loc ->
            ( { model | route = Route.parse loc }, Cmd.none )

        InputClientLogWithId id ->
            ( model, Ports.inputClientLogWithId { id = id, maxSize = config.maxSize } )

        InputMaxSize s ->
            case String.toInt s of
                Ok s ->
                    ( { model | config = { config | maxSize = s } }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        MapsSearch ps ->
            ( model
            , Route.Maps ps
                |> Route.stringify
                -- |> Debug.log "maps-search"
                |> Navigation.modifyUrl
            )

        HistorySearch ps ->
            ( model
            , Route.History ps
                |> Route.stringify
                -- |> Debug.log "history-search"
                |> Navigation.modifyUrl
            )

        RouteTo route ->
            ( model
            , route
                |> Route.stringify
                -- |> Debug.log "route-to"
                |> Navigation.modifyUrl
            )

        RecvLogLine raw ->
            case LogLine.parse raw of
                Ok line ->
                    model
                        |> updateLine line
                        |> Tuple.mapFirst (updateRawLine raw)

                Err err ->
                    ( { model | parseError = Just err }, Cmd.none )

        RecvProgress p ->
            let
                m =
                    { model | progress = Just p }
            in
                if isProgressDone p then
                    -- man, I love elm, but conditional logging is so awkward
                    let
                        _ =
                            -- if this is the first completed progress, it's the history file - log something
                            if Maybe.Extra.unwrap True (not << isProgressDone) model.progress then
                                Debug.log "start from last logline" <| "?tickStart=" ++ toString (Maybe.Extra.unwrap 0 Date.toTime m.instance.joinedAt)
                            else
                                ""
                    in
                        ( tick p.updatedAt m, Ports.progressComplete { name = p.name } )
                else
                    ( m, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.logline RecvLogLine
        , Ports.progress RecvProgress

        -- Slow down animation, deliberately - don't eat poe's cpu
        -- , AnimationFrame.times Tick
        , Time.every (Time.second * 1) Tick
        ]


progressPercent : Progress -> Float
progressPercent { val, max } =
    toFloat val
        / toFloat (Basics.max 1 max)
        |> clamp 0 1


isProgressDone : Progress -> Bool
isProgressDone p =
    progressPercent p >= 1


isReady : Model -> Bool
isReady =
    Maybe.Extra.unwrap False isProgressDone << .progress


progressDuration : Progress -> Time.Time
progressDuration p =
    p.updatedAt - p.startedAt
