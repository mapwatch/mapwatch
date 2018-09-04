module Mapwatch exposing
    ( Model
    , Msg(..)
    , Progress
    , init
    , initModel
    , isProgressDone
    , isReady
    , progressDuration
    , progressPercent
    , subscriptions
    , tick
    , update
    )

import Date
import Mapwatch.Instance as Instance
import Mapwatch.LogLine as LogLine
import Mapwatch.Run as Run
import Mapwatch.Visit as Visit
import Mapwatch.Zone as Zone
import Maybe.Extra
import Ports
import Time


type alias Progress =
    Ports.Progress


type alias Model =
    { progress : Maybe Progress
    , parseError : Maybe LogLine.ParseError
    , instance : Instance.State
    , runState : Run.State
    , runs : List Run.Run
    }


type Msg
    = RecvLogLine String
    | RecvProgress Progress


initModel : Model
initModel =
    { parseError = Nothing
    , progress = Nothing
    , instance = Instance.init
    , runState = Run.Empty
    , runs = []
    }


init =
    ( initModel, Cmd.none )


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
                Ports.sendJoinInstance (Instance.unsafeJoinedAt instance) instance.val visit runState lastRun
    in
    ( { model
        | instance = instance

        -- , visits = Maybe.Extra.unwrap model.visits (\v -> v :: model.visits) visit
        , runState = runState
        , runs = runs
      }
    , cmd
    )


tick : Time.Time -> Model -> Model
tick t model =
    let
        ( runState, lastRun ) =
            Run.tick (Date.fromTime t) model.instance model.runState

        runs =
            case lastRun of
                Just lastRun ->
                    lastRun :: model.runs

                Nothing ->
                    model.runs
    in
    { model | runState = runState, runs = runs }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RecvLogLine raw ->
            case LogLine.parse raw of
                Ok line ->
                    updateLine line model

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
