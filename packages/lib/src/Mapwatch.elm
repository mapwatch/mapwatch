module Mapwatch exposing
    ( Model
    , Msg(..)
    , Progress
    , init
    , initModel
    , isProgressDone
    , isReady
    , lastUpdatedAt
    , progressDuration
    , progressPercent
    , subscriptions
    , tick
    , update
    )

import Duration exposing (Millis)
import Mapwatch.Instance as Instance
import Mapwatch.LogLine as LogLine
import Mapwatch.Run as Run
import Mapwatch.Visit as Visit
import Mapwatch.Zone as Zone
import Maybe.Extra
import Ports
import Time


type alias Progress =
    { val : Int
    , max : Int
    , startedAt : Time.Posix
    , updatedAt : Time.Posix
    , name : String
    }


type alias Model =
    { progress : Maybe Progress
    , parseError : Maybe LogLine.ParseError
    , instance : Instance.State
    , runState : Run.State
    , runs : List Run.Run
    }


type Msg
    = RecvLogLine { date : Int, line : String }
    | RecvProgress Ports.Progress


initModel : Model
initModel =
    { parseError = Nothing
    , progress = Nothing
    , instance = Instance.init
    , runState = Run.Empty
    , runs = []
    }


init : ( Model, Cmd Msg )
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
                Just lastRun_ ->
                    lastRun_ :: model.runs

                Nothing ->
                    model.runs

        cmd =
            if instance.joinedAt == model.instance.joinedAt then
                Cmd.none

            else
                case instance.joinedAt of
                    Nothing ->
                        Cmd.none

                    Just joinedAt ->
                        Ports.sendJoinInstance joinedAt instance.val visit runState lastRun
    in
    ( { model
        | instance = instance

        -- , visits = Maybe.Extra.unwrap model.visits (\v -> v :: model.visits) visit
        , runState = runState
        , runs = runs
      }
    , cmd
    )


tick : Time.Posix -> Model -> Model
tick t model =
    let
        ( runState, lastRun ) =
            Run.tick t model.instance model.runState

        runs =
            case lastRun of
                Just lastRun_ ->
                    lastRun_ :: model.runs

                Nothing ->
                    model.runs
    in
    { model | runState = runState, runs = runs }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RecvLogLine raw ->
            case LogLine.parse (Time.millisToPosix raw.date) raw.line of
                Ok line ->
                    updateLine line model

                Err err ->
                    ( { model | parseError = Just err }, Cmd.none )

        RecvProgress p0 ->
            let
                p =
                    { val = p0.val
                    , max = p0.max
                    , name = p0.name
                    , startedAt = Time.millisToPosix p0.startedAt
                    , updatedAt = Time.millisToPosix p0.updatedAt
                    }

                m =
                    { model | progress = Just p }
            in
            if isProgressDone p then
                -- man, I love elm, but conditional logging is so awkward
                -- let
                -- _ =
                -- if this is the first completed progress, it's the history file - log something
                -- if Maybe.Extra.unwrap True (not << isProgressDone) model.progress then
                -- Debug.log "start from last logline" <| "?tickStart=" ++ String.fromInt (Maybe.Extra.unwrap 0 Time.posixToMillis m.instance.joinedAt)
                -- else
                -- ""
                -- in
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


progressDuration : Progress -> Millis
progressDuration p =
    Time.posixToMillis p.updatedAt - Time.posixToMillis p.startedAt


lastUpdatedAt : Model -> Maybe Time.Posix
lastUpdatedAt model =
    [ model.runState |> Run.stateLastUpdatedAt
    , model.runs |> List.reverse |> List.head |> Maybe.map (\r -> r.last.leftAt)
    ]
        |> List.filterMap identity
        |> List.head
