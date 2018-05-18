module View exposing (view)

import Html as H
import Html.Attributes as A
import Html.Events as E
import Json.Decode as Decode
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
    let
        d =
            MapRun.durations run
    in
        H.li []
            [ H.text <|
                (Maybe.withDefault "(unknown)" run.startZone)
                    ++ ": "
                    ++ formatDuration d.start
                    ++ " map + "
                    ++ formatDuration d.subs
                    ++ " sidezones + "
                    ++ formatDuration d.town
                    ++ " town ("
                    ++ (toString run.portals)
                    ++ " portals) = "
                    ++ formatDuration d.total
                    ++ " total"
            , H.ul [] (List.map (uncurry viewMapSub) <| Dict.toList run.durations)

            -- , H.ul [] [ H.li [] [ H.text <| toString run.entries ] ]
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

        hpad =
            (if h > 0 then
                [ pad0 2 h ]
             else
                []
            )
    in
        -- String.join ":" <| [ pad0 2 h, pad0 2 m, pad0 2 s, pad0 4 ms ]
        String.join ":" <| hpad ++ [ pad0 2 m, pad0 2 s ]


viewConfig : Model -> H.Html Msg
viewConfig model =
    -- H.form [ E.onSubmit StartWatching ]
    H.form []
        [ H.div []
            (let
                id =
                    "clientTxt"
             in
                [ H.text "PoE Client.txt: "
                , H.input [ A.type_ "file", A.id id, E.on "change" (Decode.succeed <| InputClientLogWithId id) ] []
                ]
            )
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
        , H.div []
            [ H.text <|
                (toString <| List.length model.runs)
                    ++ " map-runs. Average: "
                    ++ (MapRun.averageDurations model.runs |> .start |> formatDuration)
                    ++ " map + "
                    ++ (MapRun.averageDurations model.runs |> .subs |> formatDuration)
                    ++ " sidezones"
            ]
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
