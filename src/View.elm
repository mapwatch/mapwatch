module View exposing (view)

import Html as H
import Html.Attributes as A
import Html.Events as E
import Json.Decode as Decode
import Time
import Dict
import Model as Model exposing (Model, Msg(..))
import Model.LogLine as LogLine
import Model.Visit as Visit
import Model.Instance as Instance exposing (Instance)
import Model.Run as Run


viewLogLine : LogLine.Line -> H.Html msg
viewLogLine line =
    H.li []
        [ H.text (toString line.date)
        , H.text (toString line.info)
        , H.div [] [ H.i [] [ H.text line.raw ] ]
        ]


formatInstance : Maybe Instance -> String
formatInstance instance =
    case instance of
        Just i ->
            i.zone ++ "@" ++ i.addr

        Nothing ->
            "(none)"


viewInstance : Maybe Instance -> H.Html msg
viewInstance instance =
    case instance of
        Just i ->
            H.span [ A.title i.addr ] [ H.text i.zone ]

        Nothing ->
            H.span [] [ H.text "(none)" ]


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


viewProgress : Model.Progress -> H.Html msg
viewProgress p =
    if Model.isProgressDone p then
        H.div [] [ H.text <| "Processed " ++ toString p.max ++ " bytes in " ++ toString (Model.progressDuration p / 1000) ++ "s" ]
    else
        H.div [] [ H.progress [ A.value (toString p.val), A.max (toString p.max) ] [] ]


viewVisit : Visit.Visit -> H.Html msg
viewVisit visit =
    H.li []
        [ H.text <|
            formatDuration (Visit.duration visit)
                ++ " -- "
                ++ formatInstance visit.instance
                ++ " "
                ++ toString { map = Visit.isMap visit, town = Visit.isTown visit, offline = Visit.isOffline visit }
        ]


formatDurationSet : Run.DurationSet -> String
formatDurationSet d =
    formatDuration d.start
        ++ " map + "
        ++ formatDuration d.subs
        ++ " sidezones + "
        ++ formatDuration d.town
        ++ " town ("
        ++ toString (floor <| 100 * (d.town / (max 1 d.all)))
        ++ "%, "
        -- to 2 decimal places. Normally this is an int, except when used for the average
        ++ toString ((d.portals * 100 |> floor |> toFloat) / 100)
        ++ " portals) = "
        ++ formatDuration d.all


viewRun : Run.Run -> H.Html msg
viewRun run =
    H.li [] [ viewInstance run.first.instance, H.text <| " -- " ++ formatDurationSet (Run.durationSet run) ]


viewResults : Model -> H.Html msg
viewResults model =
    let
        today =
            Run.filterToday model.now model.runs
    in
        H.div []
            [ H.div [] []
            , H.div [] [ H.text <| "Today: " ++ toString (List.length today) ++ " finished runs" ]
            , H.ul []
                [ H.li [] [ H.text <| "total: " ++ formatDurationSet (Run.totalDurationSet today) ]
                , H.li [] [ H.text <| "average: " ++ formatDurationSet (Run.meanDurationSet today) ]
                ]
            , H.div [] [ H.text <| "All-time: " ++ toString (List.length model.runs) ++ " finished runs" ]
            , H.ul []
                [ H.li [] [ H.text <| "total: " ++ formatDurationSet (Run.totalDurationSet model.runs) ]
                , H.li [] [ H.text <| "average: " ++ formatDurationSet (Run.meanDurationSet model.runs) ]
                ]
            , H.div [] [ H.text "Current instance: ", viewInstance model.instance.val, H.text <| " " ++ toString { map = Instance.isMap model.instance.val, town = Instance.isTown model.instance.val } ]
            , H.div [] [ H.text <| "All runs: " ]
            , H.ul [] (List.map viewRun model.runs)
            ]


viewMain : Model -> H.Html Msg
viewMain model =
    case model.progress of
        Nothing ->
            -- waiting for file input, nothing to show yet
            H.div [] []

        Just p ->
            H.div [] <|
                (if Model.isProgressDone p then
                    -- all done!
                    [ viewResults model ]
                 else
                    []
                )
                    ++ [ viewProgress p ]


view : Model -> H.Html Msg
view model =
    H.div []
        [ viewConfig model
        , viewParseError model.parseError
        , viewMain model
        ]
