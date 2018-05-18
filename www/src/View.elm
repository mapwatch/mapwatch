module View exposing (view)

import Html as H
import Html.Attributes as A
import Html.Events as E
import Time
import Dict
import LogLine
import Model as Model exposing (Model, Msg(..))
import Entry as Entry exposing (Instance, Entry)
import MapRun as MapRun exposing (MapRun)


viewLogLine : LogLine.Line -> H.Html msg
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


viewEntry : Entry -> H.Html msg
viewEntry entry =
    H.li []
        [ H.text <|
            toString entry.at
                ++ ": "
                ++ instanceToString entry.instance
                ++ ", "
                ++ toString (Entry.zoneType entry)
        ]


viewMapSub : String -> Time.Time -> H.Html msg
viewMapSub zone dur =
    H.li [] [ H.text <| zone ++ ": " ++ formatDuration dur ]


viewMapRun : MapRun -> H.Html msg
viewMapRun run =
    H.li []
        [ H.text <| (Maybe.withDefault "(unknown)" run.startZone) ++ ": " ++ formatDuration (MapRun.totalDuration run)
        , H.ul [] (List.map (uncurry viewMapSub) <| Dict.toList run.durations)
        ]


formatDuration : Float -> String
formatDuration dur0 =
    let
        dur =
            floor dur0

        h =
            dur // (truncate Time.hour)

        m =
            dur % (truncate Time.hour) // (truncate Time.minute)

        s =
            dur % (truncate Time.minute) // (truncate Time.second)

        ms =
            dur % (truncate Time.second)

        pad0 length num =
            num
                |> toString
                |> String.padLeft length '0'
    in
        String.join ":" [ pad0 2 h, pad0 2 m, pad0 2 s, pad0 4 ms ]


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


viewParseError : Maybe LogLine.ParseError -> H.Html msg
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
        , viewParseError model.parseError
        , H.text "map-runs:"
        , H.ul []
            (case MapRun.fromCurrentEntries model.now model.entries of
                Nothing ->
                    [ H.li [] [ H.text "(not currently running)" ] ]

                Just run ->
                    [ viewMapRun run ]
            )
        , H.ul [] (List.map viewMapRun model.runs)
        , H.text "pending-entries:"
        , H.ul [] (List.map viewEntry model.entries)
        , H.text "pending-lines:"
        , H.ul [] (List.map viewLogLine model.lines)
        ]
