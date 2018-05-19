module Model
    exposing
        ( Model
        , Msg(..)
        , Progress
        , init
        , update
        , subscriptions
        , isProgressDone
        , progressDuration
        )

import Set
import Date
import Time
import Ports
import AnimationFrame
import Model.LogLine as LogLine
import Model.Entry as Entry
import Model.MapRun as MapRun
import Model.Zone as Zone
import Model.Instance as Instance
import Model.Visit as Visit
import Model.Run as Run


type alias Flags =
    { loadedAt : Float
    }


type alias Progress =
    Ports.Progress


type alias Model =
    { loadedAt : Date.Date
    , progress : Maybe Progress
    , now : Date.Date
    , parseError : Maybe LogLine.ParseError
    , instance : Instance.State
    , visits : List Visit.Visit
    , runState : Run.State
    , runs2 : List Run.Run

    -- TODO remove the stuff below
    , lines : List LogLine.Line
    , entries : List Entry.Entry
    , runs : List MapRun.MapRun
    }


type Msg
    = Tick Date.Date
    | InputClientLogWithId String
    | RecvLogLine String
    | RecvProgress Progress


initModel : Flags -> Model
initModel flags =
    let
        loadedAt =
            Date.fromTime flags.loadedAt
    in
        { parseError = Nothing
        , progress = Nothing
        , loadedAt = loadedAt
        , now = loadedAt
        , instance = Instance.init
        , visits = []
        , runState = Run.Empty
        , runs2 = []

        -- TODO delete below
        , lines = []
        , entries = []
        , runs = []
        }


init flags =
    ( initModel flags, Cmd.none )


updateLine : LogLine.Line -> Model -> Model
updateLine line model =
    let
        instance =
            Instance.update line model.instance

        visit =
            Visit.tryInit model.instance instance

        ( runState, lastRun ) =
            Run.update instance.val visit model.runState

        runs =
            case lastRun of
                Just lastRun ->
                    lastRun :: model.runs2

                Nothing ->
                    model.runs2
    in
        { model
            | instance = instance

            -- , visits = visit |> Maybe.map (\v -> v :: model.visits) |> Maybe.withDefault model.visits
            , runState = runState
            , runs2 = runs
        }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick now ->
            ( { model | now = now }, Cmd.none )

        InputClientLogWithId id ->
            ( model, Ports.inputClientLogWithId id )

        RecvLogLine raw ->
            (case LogLine.parse raw of
                Ok line ->
                    updateLine line model

                Err err ->
                    { model | parseError = Just err }
            )
                |> \m -> ( m, Cmd.none )

        -- |> updateLogLines raw
        -- |> updateEntries
        -- |> updateMapRuns
        RecvProgress p ->
            ( { model | progress = Just p }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.logline RecvLogLine
        , Ports.progress RecvProgress
        , AnimationFrame.times (Tick << Date.fromTime)
        ]


progressPercent : Progress -> Float
progressPercent { val, max } =
    toFloat val
        / toFloat max
        |> clamp 0 1


isProgressDone : Progress -> Bool
isProgressDone p =
    progressPercent p >= 1


progressDuration : Progress -> Time.Time
progressDuration p =
    p.updatedAt - p.startedAt
