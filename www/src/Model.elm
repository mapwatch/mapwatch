module Model
    exposing
        ( Model
        , Msg(..)
        , init
        , update
        , subscriptions
        )

import Set
import Date
import Time
import Ports
import LogLine
import Entry
import MapRun
import Zone
import AnimationFrame


type alias Flags =
    { wshost : String
    }


type alias Model =
    { config : Ports.Config
    , now : Date.Date
    , parseError : Maybe LogLine.ParseError
    , lines : List LogLine.Line
    , entries : List Entry.Entry
    , runs : List MapRun.MapRun
    }


type Msg
    = Tick Date.Date
    | StartWatching
    | InputClientLog String
    | InputClientLogPath String
    | RecvLogLine String


initModel : Flags -> Model
initModel flags =
    { parseError = Nothing
    , now = Date.fromTime 0
    , lines = []
    , entries = []
    , runs = []
    , config =
        { wshost = flags.wshost
        , clientLogPath = "../Client.txt"
        }
    }


init flags =
    initModel flags
        |> update StartWatching


updateLogLines : String -> Model -> Model
updateLogLines raw model =
    case LogLine.parse raw of
        Ok line ->
            { model
                | parseError = Nothing
                , lines = line :: model.lines
            }

        Err err ->
            { model
                | parseError = Just err
            }


updateEntries : Model -> Model
updateEntries model =
    case Entry.fromLogLines model.lines of
        Nothing ->
            model

        Just entry ->
            { model
                | lines = []
                , entries = entry :: model.entries
            }


updateMapRuns : Model -> Model
updateMapRuns model =
    case MapRun.fromEntries model.entries of
        Nothing ->
            model

        Just ( run, entries ) ->
            if run.startZone |> Maybe.map Zone.isMap |> Maybe.withDefault False then
                { model
                    | entries = entries
                    , runs = run :: model.runs
                }
            else
                -- it's not an actual map-run: remove the relevant zone-entries, but don't show the map-run
                { model | entries = entries }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick now ->
            ( { model | now = now }, Cmd.none )

        StartWatching ->
            ( model, Ports.startWatching model.config )

        InputClientLogPath path ->
            let
                config =
                    model.config
            in
                ( { model | config = { config | clientLogPath = path } }, Cmd.none )

        InputClientLog id ->
            ( model, Ports.inputClientLog id )

        RecvLogLine raw ->
            model
                |> updateLogLines raw
                |> updateEntries
                |> updateMapRuns
                |> \m -> ( m, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.logline RecvLogLine
        , AnimationFrame.times (Tick << Date.fromTime)
        ]
