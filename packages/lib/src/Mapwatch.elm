module Mapwatch exposing
    ( Model
    , Msg(..)
    , OkModel
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
import Time


type alias Progress =
    { val : Int
    , max : Int
    , startedAt : Time.Posix
    , updatedAt : Time.Posix
    , name : String
    }


type alias Model =
    Result String OkModel


type alias OkModel =
    { datamine : Datamine
    , progress : Maybe Progress
    , parseError : Maybe LogLine.ParseError
    , instance : Maybe Instance.State
    , runState : Run.State
    , runs : List Run.Run
    }


type Msg
    = RecvLogLine { date : Int, line : String }
    | RecvProgress Ports.Progress


createModel : Datamine -> OkModel
createModel datamine =
    { datamine = datamine
    , parseError = Nothing
    , progress = Nothing
    , instance = Nothing
    , runState = Run.Empty
    , runs = []
    }


initModel : D.Value -> Model
initModel =
    D.decodeValue Datamine.decoder
        >> Result.mapError D.errorToString
        >> Result.map createModel


init : D.Value -> ( Model, Cmd Msg )
init datamineJson =
    ( initModel datamineJson, Cmd.none )


updateLine : Datamine -> LogLine.Line -> OkModel -> ( OkModel, Cmd Msg )
updateLine datamine line model =
    let
        instance =
            Instance.initOrUpdate datamine line model.instance

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
            case model.instance of
                Nothing ->
                    Cmd.none

                Just i ->
                    if instance.joinedAt == i.joinedAt then
                        Cmd.none

                    else
                        Ports.sendJoinInstance instance.joinedAt instance.val visit runState lastRun
    in
    ( { model
        | instance = Just instance

        -- , visits = Maybe.Extra.unwrap model.visits (\v -> v :: model.visits) visit
        , runState = runState
        , runs = runs
      }
    , cmd
    )


tick : Time.Posix -> OkModel -> OkModel
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


update : Msg -> Model -> ( Model, Cmd Msg )
update msg rmodel =
    case rmodel of
        Err err ->
            ( rmodel, Cmd.none )

        Ok model ->
            updateOk msg model
                |> Tuple.mapFirst Ok


updateOk : Msg -> OkModel -> ( OkModel, Cmd Msg )
updateOk msg model =
    case msg of
        RecvLogLine raw ->
            case LogLine.parse (Time.millisToPosix raw.date) raw.line of
                Ok line ->
                    updateLine model.datamine line model

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


isReady : OkModel -> Bool
isReady =
    .progress >> Maybe.Extra.unwrap False isProgressDone


progressDuration : Progress -> Millis
progressDuration p =
    Time.posixToMillis p.updatedAt - Time.posixToMillis p.startedAt


lastUpdatedAt : OkModel -> Maybe Time.Posix
lastUpdatedAt model =
    [ model.runState |> Run.stateLastUpdatedAt
    , model.runs |> List.reverse |> List.head |> Maybe.map (\r -> r.last.leftAt)
    ]
        |> List.filterMap identity
        |> List.head
