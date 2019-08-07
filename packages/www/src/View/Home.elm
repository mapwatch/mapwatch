module View.Home exposing (formatBytes, formatDuration, formatSideAreaType, maskedText, selfUrl, viewDate, viewHeader, viewInstance, viewParseError, viewProgress, viewSideAreaName)

-- TODO: This used to be its own page. Now it's a graveyard of functions that get
-- called from other pages. I should really clean it up and find these a new home.

import Dict
import Html as H
import Html.Attributes as A
import Html.Events as E
import ISO8601
import Mapwatch as Mapwatch exposing (Model, Msg(..))
import Mapwatch.Instance as Instance exposing (Instance)
import Mapwatch.LogLine as LogLine
import Mapwatch.Run as Run
import Mapwatch.Visit as Visit
import Mapwatch.Zone as Zone
import Route
import Time
import View.Icon as Icon
import View.Nav
import View.Setup


viewInstance : Route.HistoryParams -> Instance -> H.Html msg
viewInstance qs instance =
    case instance of
        Instance.Instance i ->
            if Zone.isMap i.zone then
                -- TODO preserve before/after
                H.a [ Route.href <| Route.History { qs | search = Just i.zone }, A.title i.addr ] [ Icon.mapOrBlank i.zone, H.text i.zone ]

            else
                H.span [ A.title i.addr ] [ H.text i.zone ]

        Instance.MainMenu ->
            H.span [] [ H.text "(none)" ]


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


viewParseError : Maybe LogLine.ParseError -> H.Html msg
viewParseError err =
    case err of
        Nothing ->
            H.div [] []

        Just err_ ->
            H.div [] [ H.text <| "Log parsing error: " ++ Debug.toString err_ ]


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


viewProgress : Mapwatch.Progress -> H.Html msg
viewProgress p =
    if Mapwatch.isProgressDone p then
        H.div [] [ H.br [] [], H.text <| "Processed " ++ formatBytes p.max ++ " in " ++ String.fromFloat (toFloat (Mapwatch.progressDuration p) / 1000) ++ "s" ]

    else if p.max <= 0 then
        H.div [] [ Icon.fasPulse "spinner" ]

    else
        H.div []
            [ H.progress [ A.value (String.fromInt p.val), A.max (String.fromInt p.max) ] []
            , H.div []
                [ H.text <|
                    formatBytes p.val
                        ++ " / "
                        ++ formatBytes p.max
                        ++ ": "
                        ++ (String.fromInt <| floor <| Mapwatch.progressPercent p * 100)
                        ++ "%"

                -- ++ " in"
                -- ++ String.fromFloat (Mapwatch.progressDuration p / 1000)
                -- ++ "s"
                ]
            ]


viewDate : Time.Posix -> H.Html msg
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
    H.span [ A.title (ISO8601.toString i) ]
        [ H.text timestamp ]


formatSideAreaType : Instance -> Maybe String
formatSideAreaType instance =
    case Zone.sideZoneType <| Instance.unwrap Nothing (Just << .zone) instance of
        Zone.OtherSideZone ->
            Nothing

        Zone.ZanaMission ->
            Just "Zana mission"

        Zone.ElderGuardian guardian ->
            Just <| "Elder Guardian: The " ++ Zone.guardianToString guardian


viewSideAreaName : Route.HistoryParams -> Instance -> H.Html msg
viewSideAreaName qs instance =
    case formatSideAreaType instance of
        Nothing ->
            viewInstance qs instance

        Just str ->
            H.span [] [ H.text <| str ++ " (", viewInstance qs instance, H.text ")" ]


maskedText : String -> H.Html msg
maskedText str =
    -- This text is hidden on the webpage, but can be copypasted. Useful for formatting shared text.
    H.span [ A.style "opacity" "0", A.style "font-size" "0", A.style "white-space" "pre" ] [ H.text str ]


selfUrl =
    "https://mapwatch.github.io"


viewHeader : H.Html msg
viewHeader =
    H.div []
        [ H.h1 [ A.class "title" ]
            [ maskedText "["

            -- , H.a [ A.href "./" ] [ Icon.fas "tachometer-alt", H.text " Mapwatch" ]
            , H.a [ A.href "#/" ] [ H.text " Mapwatch" ]
            , maskedText <| "](" ++ selfUrl ++ ")"
            ]
        , H.small []
            [ H.text " - automatically time your Path of Exile map clears" ]
        ]
