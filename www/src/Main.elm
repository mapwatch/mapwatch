module Main exposing (main)

import Date
import Time
import Regex
import Ports
import Set
import Html as H
import Html.Attributes as A
import Html.Events as E


towns : Set.Set String
towns =
    Set.fromList
        [ "Oriath", "Enlightened Hideout" ]


main =
    H.programWithFlags
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type alias Flags =
    { wshost : String
    }


type alias Model =
    { config : Ports.Config
    , parseError : Maybe ParseError
    , linebuf : List LogLine
    , current : Maybe CurrentInstance
    , entries : List InstanceEntry
    , runs : List MapRun
    }


type Msg
    = StartWatching
    | InputClientLogPath String
    | RecvLogLine String


type alias MapRun =
    { instance : Instance
    , start : Date.Date
    , duration : Time.Time
    , townDuration : Time.Time
    }


type alias LogLine =
    { raw : String
    , date : Date.Date
    , info : LogInfo
    }


type alias ParseError =
    { raw : String, err : String }


type alias ParsedLogLine =
    Result ParseError LogLine


type LogInfo
    = Opening
    | ConnectingToInstanceServer String
    | YouHaveEntered String


type alias Instance =
    { zone : String, addr : String }


type alias InstanceEntry =
    { instance : Maybe Instance, at : Date.Date, dur : Time.Time, last : Bool }


type alias CurrentInstance =
    { instance : Maybe Instance, at : Date.Date }


regexParseFirst : String -> String -> Maybe Regex.Match
regexParseFirst regex txt =
    txt
        |> Regex.find (Regex.AtMost 1) (Regex.regex regex)
        |> List.head


regexParseFirstRes : String -> err -> String -> Result err Regex.Match
regexParseFirstRes regex err txt =
    regexParseFirst regex txt |> Result.fromMaybe err


parseLogInfo : String -> Maybe LogInfo
parseLogInfo raw =
    let
        parseOpening =
            case regexParseFirst "LOG FILE OPENING" raw of
                Just _ ->
                    Just Opening

                _ ->
                    Nothing

        parseEntered =
            case regexParseFirst "You have entered (.*)\\.$" raw |> Maybe.map .submatches of
                Just [ Just zone ] ->
                    Just <| YouHaveEntered zone

                _ ->
                    Nothing

        parseConnecting =
            case regexParseFirst "Connecting to instance server at (.*)$" raw |> Maybe.map .submatches of
                Just [ Just addr ] ->
                    Just <| ConnectingToInstanceServer addr

                _ ->
                    Nothing
    in
        [ parseOpening, parseEntered, parseConnecting ]
            -- use the first matching parser
            |> List.map (Maybe.withDefault [] << Maybe.map List.singleton)
            |> List.concat
            |> List.head


parseLogLine : String -> ParsedLogLine
parseLogLine raw =
    let
        date : Result String Date.Date
        date =
            raw
                -- rearrange the date so the built-in js parser likes it
                |> regexParseFirstRes "\\d{4}/\\d{2}/\\d{2} \\d{2}:\\d{2}:\\d{2}" "no date in logline"
                |> Result.map (Regex.split Regex.All (Regex.regex "[/: ]") << .match)
                |> Result.andThen
                    (\strs ->
                        case strs of
                            [ yr, mo, d, h, mn, s ] ->
                                Date.fromString <| (String.join "-" [ yr, mo, d ]) ++ "T" ++ (String.join ":" [ h, mn, s ]) ++ "Z"

                            _ ->
                                Err ("date parsed-count mismatch: " ++ toString strs)
                    )

        result d i =
            { raw = raw
            , date = d
            , info = i
            }

        info =
            parseLogInfo raw
                |> Result.fromMaybe "logline not recognized"

        error err =
            { err = err, raw = raw }
    in
        Result.map2 result date info
            |> Result.mapError error


initModel : Flags -> Model
initModel flags =
    { linebuf = []
    , parseError = Nothing
    , current = Nothing
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
    case parseLogLine raw of
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
                        (YouHaveEntered zone) :: (ConnectingToInstanceServer addr) :: _ ->
                            Just { instance = Just { zone = zone, addr = addr }, at = first.date }

                        Opening :: _ ->
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


viewLogLine : LogLine -> H.Html msg
viewLogLine line =
    H.li []
        [ H.text (toString line.date)
        , H.text (toString line.info)
        , H.div [] [ H.i [] [ H.text line.raw ] ]
        ]


instanceToString : Maybe Instance -> String
instanceToString instance =
    case instance of
        Just i ->
            i.zone ++ "@" ++ i.addr

        Nothing ->
            "(none)"


viewInstanceEntry : InstanceEntry -> H.Html msg
viewInstanceEntry entry =
    H.li []
        [ H.text <|
            toString entry.at
                ++ ": "
                ++ toString entry.dur
                ++ "ms"
                ++ (if entry.last then
                        "????"
                    else
                        ""
                   )
                ++ ", "
                ++ instanceToString entry.instance
        ]


viewCurrentInstance : Maybe CurrentInstance -> H.Html msg
viewCurrentInstance cur =
    case cur of
        Just entry ->
            H.ul [] [ H.li [] [ H.text <| toString entry.at ++ ": (now), " ++ instanceToString entry.instance ] ]

        Nothing ->
            H.ul [] [ H.li [] [ H.text "(none yet)" ] ]


viewConfig : Model -> H.Html Msg
viewConfig model =
    H.form [ E.onSubmit StartWatching ]
        [ H.div []
            [ H.text "local log server: "
            , H.input [ A.disabled True, A.type_ "text", A.value model.config.wshost ] []
            ]
        , H.div []
            [ H.text "path to PoE Client.txt: "
            , H.input [ A.type_ "text", E.onInput InputClientLogPath, A.value model.config.clientLogPath ] []
            ]
        , H.div [] [ H.button [ A.type_ "submit" ] [ H.text "Watch" ] ]
        ]


viewParseError : Maybe ParseError -> H.Html msg
viewParseError err =
    case err of
        Nothing ->
            H.div [] []

        Just err ->
            H.div [] [ H.text <| "Log parsing error: " ++ toString err ]


view : Model -> H.Html Msg
view model =
    H.div []
        [ H.text "Hello elm-world!"
        , viewConfig model
        , H.text "instance-entries:"
        , viewCurrentInstance model.current
        , H.ul [] (List.map viewInstanceEntry model.entries)
        , viewParseError model.parseError
        , H.text "linebuf:"
        , H.ul [] (List.map viewLogLine model.linebuf)
        ]
