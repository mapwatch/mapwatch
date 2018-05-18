module Model
    exposing
        ( Model
        , Msg(..)
        , CurrentInstance
        , InstanceEntry
        , Instance
        , init
        , update
        , subscriptions
        )

import Set
import Date
import Time
import LogLine
import Ports


towns : Set.Set String
towns =
    Set.fromList
        [ "Oriath", "Enlightened Hideout" ]


type alias Flags =
    { wshost : String
    }


type alias Model =
    { config : Ports.Config
    , parseError : Maybe LogLine.ParseError
    , linebuf : List LogLine.Line
    , current : Maybe CurrentInstance
    , entries : List InstanceEntry
    }


type Msg
    = StartWatching
    | InputClientLogPath String
    | RecvLogLine String


type alias Instance =
    { zone : String, addr : String }


type alias InstanceEntry =
    { instance : Maybe Instance, at : Date.Date, dur : Time.Time, last : Bool }


type alias CurrentInstance =
    { instance : Maybe Instance, at : Date.Date }


initModel : Flags -> Model
initModel flags =
    { linebuf = []
    , parseError = Nothing
    , current = Nothing
    , entries = []
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
                , linebuf = line :: model.linebuf
            }

        Err err ->
            { model
                | parseError = Just err
            }


updateInstanceEntries : Model -> Model
updateInstanceEntries model =
    let
        prev : Maybe CurrentInstance
        prev =
            model.current

        current : Maybe CurrentInstance
        current =
            case List.head model.linebuf of
                Nothing ->
                    Nothing

                Just first ->
                    case model.linebuf |> List.take 2 |> List.map .info of
                        (LogLine.YouHaveEntered zone) :: (LogLine.ConnectingToInstanceServer addr) :: _ ->
                            Just { instance = Just { zone = zone, addr = addr }, at = first.date }

                        LogLine.Opening :: _ ->
                            Just { instance = Nothing, at = first.date }

                        _ ->
                            Nothing

        nextEntry : CurrentInstance -> CurrentInstance -> InstanceEntry
        nextEntry prev current =
            { instance = prev.instance
            , at = prev.at
            , dur = (Date.toTime current.at) - (Date.toTime prev.at)
            , last =
                case current.instance of
                    Just _ ->
                        False

                    Nothing ->
                        True
            }

        entries =
            case Maybe.map2 nextEntry prev current of
                Nothing ->
                    model.entries

                Just entry ->
                    entry :: model.entries
    in
        case current of
            Just _ ->
                { model
                    | current = current
                    , entries = entries
                    , linebuf = []
                }

            Nothing ->
                model


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StartWatching ->
            ( model, Ports.startWatching model.config )

        InputClientLogPath path ->
            let
                config =
                    model.config
            in
                ( { model | config = { config | clientLogPath = path } }, Cmd.none )

        RecvLogLine raw ->
            model
                |> updateLogLines raw
                |> updateInstanceEntries
                |> \m -> ( m, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.logline RecvLogLine
        ]
