module View.Home exposing (formatBytes, formatDuration, formatSideAreaType, maskedText, selfUrl, viewDate, viewHeader, viewInstance, viewMaybeInstance, viewParseError, viewProgress, viewSideAreaName)

-- TODO: This used to be its own page. Now it's a graveyard of functions that get
-- called from other pages. I should really clean it up and find these a new home.

import Dict
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import ISO8601
import Mapwatch as Mapwatch exposing (Model, Msg(..))
import Mapwatch.Datamine as Datamine exposing (Datamine)
import Mapwatch.Instance as Instance exposing (Instance)
import Mapwatch.LogLine as LogLine
import Mapwatch.Run as Run
import Mapwatch.Visit as Visit
import Route
import Time
import TimedReadline exposing (Progress)
import View.Icon as Icon
import View.Nav
import View.Setup


viewMaybeInstance : Route.HistoryParams -> Maybe Instance -> Html msg
viewMaybeInstance qs instance =
    case instance of
        Just ((Instance.Instance addr) as i) ->
            if Instance.isMap i then
                -- TODO preserve before/after
                a [ Route.href <| Route.History { qs | search = Just addr.zone }, title addr.addr ] [ Icon.mapOrBlank addr.worldArea, text addr.zone ]

            else
                span [ title addr.addr ] [ text addr.zone ]

        Just Instance.MainMenu ->
            span [] [ text "(none)" ]

        Nothing ->
            span [] [ text "(none)" ]


viewInstance : Route.HistoryParams -> Instance -> Html msg
viewInstance qs =
    Just >> viewMaybeInstance qs


time =
    { second = 1000
    , minute = 1000 * 60
    , hour = 1000 * 60 * 60
    , day = 1000 * 60 * 60 * 24
    }


formatDuration : Int -> String
formatDuration dur =
    let
        sign =
            if dur >= 0 then
                ""

            else
                "-"

        d =
            abs <| dur // truncate time.day

        h =
            abs <| remainderBy (truncate time.day) dur // truncate time.hour

        m =
            abs <| remainderBy (truncate time.hour) dur // truncate time.minute

        s =
            abs <| remainderBy (truncate time.minute) dur // truncate time.second

        ms =
            abs <| remainderBy (truncate time.second) dur

        pad0 : Int -> Int -> String
        pad0 length =
            String.fromInt
                >> String.padLeft length '0'

        hpad =
            if h > 0 then
                [ pad0 2 h ]

            else
                []

        dpad =
            if d > 0 then
                [ String.fromInt d ]

            else
                []
    in
    -- String.join ":" <| [ pad0 2 h, pad0 2 m, pad0 2 s, pad0 4 ms ]
    sign ++ String.join ":" (dpad ++ hpad ++ [ pad0 2 m, pad0 2 s ])


viewParseError : Maybe LogLine.ParseError -> Html msg
viewParseError err =
    case err of
        Nothing ->
            div [] []

        Just err_ ->
            div [] [ text <| "Log parsing error: " ++ LogLine.parseErrorToString err_ ]


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

        places n val_ =
            String.fromFloat <| (toFloat <| floor <| val_ * (10 ^ n)) / (10 ^ n)
    in
    places 2 val ++ unit


viewProgress : Progress -> Html msg
viewProgress p =
    if p.isDone then
        div [] [ br [] [], text <| "Processed " ++ formatBytes p.max ++ " in " ++ String.fromFloat (toFloat p.durationMillis / 1000) ++ "s" ]

    else
        div []
            [ progress [ value (String.fromInt p.value), A.max (String.fromInt p.max) ] []
            , div []
                [ text <|
                    formatBytes p.max
                        ++ " / "
                        ++ formatBytes p.max
                        ++ ": "
                        ++ (String.fromInt <| floor <| p.percent * 100)
                        ++ "%"

                -- ++ " in"
                -- ++ String.fromFloat (Mapwatch.progressDuration p / 1000)
                -- ++ "s"
                ]
            ]


viewDate : Time.Posix -> Html msg
viewDate d =
    let
        i =
            d |> ISO8601.fromPosix

        months =
            [ "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" ]

        monthNum =
            ISO8601.month i

        m =
            if monthNum < 1 then
                String.fromInt monthNum

            else
                months |> List.drop (monthNum - 1) |> List.head |> Maybe.withDefault (String.fromInt monthNum)

        timestamp =
            String.join " "
                [ m
                , ISO8601.day i |> String.fromInt |> String.padLeft 2 '0'
                , String.join ":"
                    [ ISO8601.hour i |> String.fromInt |> String.padLeft 2 '0'
                    , ISO8601.minute i |> String.fromInt |> String.padLeft 2 '0'
                    ]
                ]
    in
    span [ title (ISO8601.toString i) ]
        [ text timestamp ]


viewSideAreaName : Route.HistoryParams -> Instance -> Html msg
viewSideAreaName qs instance =
    case Instance.worldArea instance of
        Nothing ->
            viewInstance qs instance

        Just w ->
            if Datamine.isMap w then
                span [] [ Icon.zana, text "Zana mission (", viewInstance qs instance, text ")" ]

            else if w.isVaalArea then
                span [] [ Icon.vaal, text "Vaal side area (", viewInstance qs instance, text ")" ]

            else if w.isLabTrial then
                span [] [ Icon.labTrial, text "Labyrinth trial (", viewInstance qs instance, text ")" ]

            else if w.isAbyssalDepths then
                span [] [ Icon.abyss, viewInstance qs instance ]

            else
                viewInstance qs instance


maskedText : String -> Html msg
maskedText str =
    -- This text is hidden on the webpage, but can be copypasted. Useful for formatting shared text.
    span [ style "opacity" "0", style "font-size" "0", style "white-space" "pre" ] [ text str ]


selfUrl =
    "https://mapwatch.erosson.org"


viewHeader : Html msg
viewHeader =
    div []
        [ h1 [ class "title" ]
            [ maskedText "["

            -- , a [ href "./" ] [ Icon.fas "tachometer-alt", text " Mapwatch" ]
            , a [ href "#/" ] [ text " Mapwatch" ]
            , maskedText <| "](" ++ selfUrl ++ ")"
            ]
        , small []
            [ text " - automatically time your Path of Exile map clears" ]
        ]
