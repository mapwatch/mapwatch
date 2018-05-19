module View exposing (view)

import Html as H
import Html.Attributes as A
import Html.Events as E
import Json.Decode as Decode
import Time
import Date
import Dict
import Model as Model exposing (Model, Msg(..))
import Model.LogLine as LogLine
import Model.Visit as Visit
import Model.Instance as Instance exposing (Instance)
import Model.Run as Run
import Model.Zone as Zone


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
    let
        display =
            case model.progress of
                Nothing ->
                    ""

                Just _ ->
                    "none"
    in
        -- H.form [ E.onSubmit StartWatching ]
        H.form
            [ A.style [ ( "display", display ) ] ]
            [ H.p []
                [ H.text "Give me your Path of Exile "
                , H.code [] [ H.text "Client.txt" ]
                , H.text " file, and I'll give you some statistics about your recent mapping activity. "
                ]
            , H.p []
                [ H.text "Then, leave me open while you play - I'll keep watching, no need to upload again."
                ]
            , H.p []
                [ H.text "Usually, the file I need is at "
                , H.code [] [ H.text "C:\\Program Files (x86)\\Grinding Gear Games\\Path of Exile\\logs\\Client.txt" ]
                , H.text " or "
                , H.code [] [ H.text "C:\\Steam\\steamapps\\common\\Path of Exile\\logs\\Client.txt" ]
                ]
            , H.hr [] []
            , H.div []
                [ H.text "Analyze only the last "
                , H.input
                    [ A.type_ "number"
                    , A.value <| toString model.config.maxSize
                    , E.onInput InputMaxSize
                    , A.min "0"
                    , A.max "100"
                    , A.tabindex 1
                    ]
                    []
                , H.text " MB of history"
                ]
            , H.div []
                (let
                    id =
                        "clientTxt"
                 in
                    [ H.text "PoE Client.txt: "
                    , H.input
                        [ A.type_ "file"
                        , A.id id
                        , E.on "change" (Decode.succeed <| InputClientLogWithId id)
                        , A.tabindex 2
                        ]
                        []
                    ]
                )
            , H.div []
                (if model.isBrowserSupported then
                    []
                 else
                    [ H.text <| "Warning: we don't support your web browser. If you have trouble, try ", H.a [ A.href "https://www.google.com/chrome/" ] [ H.text "Chrome" ], H.text "." ]
                )
            ]


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
        H.div [] [ H.text <| "Processed " ++ formatBytes p.max ++ " in " ++ toString (Model.progressDuration p / 1000) ++ "s" ]
    else
        H.div []
            [ H.progress [ A.value (toString p.val), A.max (toString p.max) ] []
            , H.div []
                [ H.text <|
                    formatBytes p.val
                        ++ " / "
                        ++ formatBytes p.max
                        ++ ": "
                        ++ toString (floor <| toFloat p.val / toFloat p.max * 100)
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
    formatDuration d.start
        ++ " map + "
        ++ (if d.subs > 0 then
                formatDuration d.subs ++ " sidezones + "
            else
                ""
           )
        ++ formatDuration d.town
        ++ " town ("
        ++ toString (clamp 0 100 <| floor <| 100 * (d.town / (max 1 d.all)))
        ++ "%, "
        -- to 2 decimal places. Normally this is an int, except when used for the average
        ++ toString ((d.portals * 100 |> floor |> toFloat) / 100)
        ++ " portals) = "
        ++ formatDuration d.all


viewDate : Date.Date -> H.Html msg
viewDate d =
    H.span [ A.title (toString d) ]
        [ H.text <| toString (Date.day d) ++ " " ++ toString (Date.month d) ]


formatSideZoneType : Maybe Instance -> Maybe String
formatSideZoneType instance =
    case Zone.sideZoneType (Maybe.map .zone instance) of
        Zone.OtherSideZone ->
            Nothing

        Zone.Mission master ->
            Just <| toString master ++ " mission"

        Zone.ElderGuardian guardian ->
            Just <| "Elder Guardian: The " ++ toString guardian


viewSideArea : Maybe Instance -> Time.Time -> H.Html msg
viewSideArea instance dur =
    let
        instanceEl =
            case formatSideZoneType instance of
                Nothing ->
                    viewInstance instance

                Just str ->
                    H.span [] [ H.text <| str ++ " (", viewInstance instance, H.text ")" ]
    in
        H.li [] [ instanceEl, H.text <| ": " ++ formatDuration dur ]


viewRunBody : Run.Run -> List (H.Html msg)
viewRunBody run =
    [ viewInstance run.first.instance
    , H.text <| " -- " ++ formatDurationSet (Run.durationSet run)
    , H.ul []
        (List.map (uncurry viewSideArea) <|
            List.filter (\( i, _ ) -> (not <| Instance.isTown i) && (i /= run.first.instance)) <|
                Run.durationPerInstance run
        )
    ]


viewRun : Run.Run -> H.Html msg
viewRun run =
    viewRunBody run
        |> (++)
            [ viewDate run.last.leftAt
            , H.text " -- "
            ]
        |> H.li []


viewResults : Model -> H.Html msg
viewResults model =
    let
        today =
            Run.filterToday model.now model.runs
    in
        H.div []
            [ H.div [] []
            , H.p [] [ H.text "You last entered: ", viewInstance model.instance.val ]
            , H.p []
                [ H.text <| "You're now mapping in: "
                , case Run.current model.now model.instance model.runState of
                    Nothing ->
                        H.span [ A.title "Slacker." ] [ H.text "(none)" ]

                    Just run ->
                        H.span [] (viewRunBody run)
                ]
            , H.div [] [ H.text <| "Today: " ++ toString (List.length today) ++ " finished runs" ]
            , H.ul []
                [ H.li [] [ H.text <| "Total: " ++ formatDurationSet (Run.totalDurationSet today) ]
                , H.li [] [ H.text <| "Average: " ++ formatDurationSet (Run.meanDurationSet today) ]
                ]
            , H.div [] [ H.text <| "All-time: " ++ toString (List.length model.runs) ++ " finished runs" ]
            , H.ul []
                [ H.li [] [ H.text <| "Total: " ++ formatDurationSet (Run.totalDurationSet model.runs) ]
                , H.li [] [ H.text <| "Average: " ++ formatDurationSet (Run.meanDurationSet model.runs) ]
                ]
            , H.div [] [ H.text <| "Your last " ++ toString (min 100 <| List.length model.runs) ++ " runs: " ]
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


view : Model -> H.Html Msg
view model =
    H.div []
        [ H.div []
            [ H.h1 [ A.style [ ( "display", "inline" ) ] ] [ H.text "Mapwatch" ]
            , H.text " - Automatically track your "
            , H.a [ A.target "_blank", A.href "https://www.pathofexile.com" ] [ H.text "Path of Exile" ]
            , H.text " mapping time"
            , H.div [ A.style [ ( "float", "right" ) ] ] [ H.a [ A.target "_blank", A.href "https://www.github.com/erosson/poe-mapwatch" ] [ H.text "Source code" ] ]
            ]
        , viewConfig model
        , viewParseError model.parseError
        , viewMain model
        ]
