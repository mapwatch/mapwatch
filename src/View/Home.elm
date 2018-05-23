module View.Home exposing (..)

import Html as H
import Html.Attributes as A
import Html.Events as E
import Time
import Date
import Dict
import Model as Model exposing (Model, Msg(..))
import Model.LogLine as LogLine
import Model.Visit as Visit
import Model.Instance as Instance exposing (Instance)
import Model.Run as Run
import Model.Zone as Zone
import View.Setup
import View.Nav
import View.Icon as Icon


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
            H.span [ A.title i.addr ] [ Icon.mapOrBlank i.zone, H.text i.zone ]

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


viewParseError : Maybe LogLine.ParseError -> H.Html msg
viewParseError err =
    case err of
        Nothing ->
            H.div [] []

        Just err ->
            H.div [] [ H.text <| "Log parsing error: " ++ toString err ]


formatBytes : Int -> String
formatBytes b =
    let
        k =
            toFloat b / 1024

        m =
            k / 1024

        g =
            m / 1024

        t =
            g / 1024

        ( val, unit ) =
            if t >= 1 then
                ( t, " TB" )
            else if g >= 1 then
                ( g, " GB" )
            else if m >= 1 then
                ( m, " MB" )
            else if k >= 1 then
                ( k, " KB" )
            else
                ( toFloat b, " bytes" )

        places n val =
            toString <| (toFloat <| floor <| val * (10 ^ n)) / (10 ^ n)
    in
        places 2 val ++ unit


viewProgress : Model.Progress -> H.Html msg
viewProgress p =
    if Model.isProgressDone p then
        H.div [] [ H.br [] [], H.text <| "Processed " ++ formatBytes p.max ++ " in " ++ toString (Model.progressDuration p / 1000) ++ "s" ]
    else if p.max <= 0 then
        H.div [] [ Icon.fasPulse "spinner" ]
    else
        H.div []
            [ H.progress [ A.value (toString p.val), A.max (toString p.max) ] []
            , H.div []
                [ H.text <|
                    formatBytes p.val
                        ++ " / "
                        ++ formatBytes p.max
                        ++ ": "
                        ++ toString (floor <| Model.progressPercent p * 100)
                        ++ "%"

                -- ++ " in"
                -- ++ toString (Model.progressDuration p / 1000)
                -- ++ "s"
                ]
            ]


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
    ""
        ++ formatDuration d.all
        ++ " = "
        ++ formatDuration d.start
        ++ " map + "
        ++ (if d.subs > 0 then
                formatDuration d.subs ++ " sidezones + "
            else
                ""
           )
        ++ formatDuration d.town
        ++ " town ("
        -- to 2 decimal places. Normally this is an int, except when used for the average
        ++ toString ((d.portals * 100 |> floor |> toFloat) / 100)
        ++ " portals, "
        ++ toString (clamp 0 100 <| floor <| 100 * (d.town / (max 1 d.all)))
        ++ "% in town)"


viewDate : Date.Date -> H.Html msg
viewDate d =
    H.span [ A.title (toString d) ]
        [ H.text <| toString (Date.day d) ++ " " ++ toString (Date.month d) ]


formatSideAreaType : Maybe Instance -> Maybe String
formatSideAreaType instance =
    case Zone.sideZoneType (Maybe.map .zone instance) of
        Zone.OtherSideZone ->
            Nothing

        Zone.Mission master ->
            Just <| toString master ++ " mission"

        Zone.ElderGuardian guardian ->
            Just <| "Elder Guardian: The " ++ toString guardian


viewSideAreaName : Maybe Instance -> H.Html msg
viewSideAreaName instance =
    case formatSideAreaType instance of
        Nothing ->
            viewInstance instance

        Just str ->
            H.span [] [ H.text <| str ++ " (", viewInstance instance, H.text ")" ]


maskedText : String -> H.Html msg
maskedText str =
    -- This text is hidden on the webpage, but can be copypasted. Useful for formatting shared text.
    H.span [ A.style [ ( "opacity", "0" ), ( "font-size", "0" ), ( "white-space", "pre" ) ] ] [ H.text str ]


viewSideArea : Instance -> Time.Time -> H.Html msg
viewSideArea instance dur =
    H.li [] [ maskedText "     * ", viewSideAreaName (Just instance), H.text <| " | " ++ formatDuration dur ]


viewRunBody : Run.Run -> List (H.Html msg)
viewRunBody run =
    [ viewInstance run.first.instance
    , H.text <| " | " ++ formatDurationSet (Run.durationSet run)
    , H.ul [] (List.map (uncurry viewSideArea) (Run.durationPerSideArea run))
    ]


viewRun : Run.Run -> H.Html msg
viewRun run =
    viewRunBody run
        |> (++)
            [ maskedText "  * "
            , viewDate run.last.leftAt
            , H.text " | "
            ]
        |> H.li []


viewResults : Model -> H.Html msg
viewResults model =
    let
        today =
            Run.filterToday model.now model.runs
    in
        H.div []
            [ H.br [] []
            , H.p [] [ H.text "You last entered: ", viewInstance model.instance.val ]
            , H.p []
                [ H.text <| "You're now mapping in: "
                , case Run.current model.now model.instance model.runState of
                    Nothing ->
                        H.span [ A.title "Slacker." ] [ H.text "(none)" ]

                    Just run ->
                        H.span [] (viewRunBody run)
                ]
            , H.p [] [ H.text <| "Today: " ++ toString (List.length today) ++ " finished runs" ]
            , H.ul []
                [ H.li [] [ maskedText "  * ", H.text <| "Total: " ++ formatDurationSet (Run.totalDurationSet today) ]
                , H.li [] [ maskedText "  * ", H.text <| "Average: " ++ formatDurationSet (Run.meanDurationSet today) ]
                ]
            , H.br [] []
            , H.p [] [ H.text <| "All-time: " ++ toString (List.length model.runs) ++ " finished runs" ]
            , H.ul []
                [ H.li [] [ maskedText "  * ", H.text <| "Total: " ++ formatDurationSet (Run.totalDurationSet model.runs) ]
                , H.li [] [ maskedText "  * ", H.text <| "Average: " ++ formatDurationSet (Run.meanDurationSet model.runs) ]
                ]
            , H.br [] []
            , H.p [] [ H.text <| "Your last " ++ toString (min 100 <| List.length model.runs) ++ " runs: " ]

            -- TODO this is a long list. Use HTML.Keyed to make updates more efficient
            , H.ul [] (List.map viewRun <| List.take 100 model.runs)
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


selfUrl =
    "https://erosson.github.com/mapwatch"


viewHeader : H.Html msg
viewHeader =
    H.div []
        [ H.h1 [ A.class "title" ]
            [ maskedText "["

            -- , H.a [ A.href "./" ] [ Icon.fas "tachometer-alt", H.text " Mapwatch" ]
            , H.a [ A.href "./" ] [ H.text " Mapwatch" ]
            , maskedText <| "](" ++ selfUrl ++ ")"
            ]
        , H.small []
            [ H.text " - passively analyze your Path of Exile mapping time" ]
        ]


view : Model -> H.Html Msg
view model =
    H.div []
        [ viewHeader
        , View.Nav.view <| Just model.route
        , View.Setup.view model
        , viewParseError model.parseError
        , viewMain model
        ]
