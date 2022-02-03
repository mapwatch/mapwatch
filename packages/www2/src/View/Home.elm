module View.Home exposing
    ( formatBytes
    , formatDuration
    , maskedText
    , monthToString
    , posixToString
    , selfUrl
    , viewAddress
    , viewDate
    , viewHeader
    , viewInstance
    , viewMaybeInstance
    , viewProgress
    , viewRegion
    , viewRun
    , viewSideAreaName
    )

-- TODO: This used to be its own page. Now it's a graveyard of functions that get
-- called from other pages. I should really clean it up and find these a new home.

import Html exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events exposing (..)
import ISO8601
import Localization.Mapwatch as L
import Mapwatch as Mapwatch exposing (Msg(..))
import Mapwatch.Datamine as Datamine exposing (WorldArea)
import Mapwatch.Instance as Instance exposing (Instance)
import Mapwatch.MapRun exposing (MapRun)
import Maybe.Extra
import Model exposing (OkModel)
import Route
import Route.QueryDict exposing (QueryDict)
import Time exposing (Posix)
import TimedReadline exposing (Progress)
import View.Icon as Icon
import View.Util


viewAddress : QueryDict -> Icon.MapIconArgs a -> Instance.Address -> Html msg
viewAddress query args addr =
    let
        blighted =
            if args.isBlightedMap then
                "Blighted "

            else
                ""
    in
    if Maybe.Extra.unwrap False Datamine.isMap addr.worldArea then
        if Maybe.Extra.unwrap False (\w -> w.isLabyrinth || w.isLabTrial) addr.worldArea then
            a [ Route.href (View.Util.insertSearch addr.zone query) Route.History, title addr.addr ] [ Icon.labTrial, text blighted, text addr.zone ]

        else
            a [ Route.href (View.Util.insertSearch addr.zone query) Route.History, title addr.addr ] [ Icon.mapOrBlank args addr.worldArea, text blighted, text addr.zone ]

    else
        span [ title addr.addr ] [ text addr.zone ]


viewMaybeInstance : QueryDict -> Maybe Instance -> Html msg
viewMaybeInstance query instance =
    case instance of
        Just (Instance.Instance addr) ->
            viewAddress query { isBlightedMap = False, isGrandHeist = Nothing } addr

        Just Instance.MainMenu ->
            span [] [ text "(none)" ]

        Nothing ->
            span [] [ text "(none)" ]


viewInstance : QueryDict -> Instance -> Html msg
viewInstance query =
    Just >> viewMaybeInstance query


viewRun : QueryDict -> MapRun -> Html msg
viewRun query run =
    viewAddress query run run.address


viewRegion : QueryDict -> Maybe WorldArea -> Html msg
viewRegion query w =
    let
        name =
            w |> Maybe.andThen .atlasRegion |> Maybe.withDefault Datamine.defaultAtlasRegion
    in
    a [ Route.href (View.Util.insertSearch name query) Route.History ] [ Icon.region w, text name ]


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

        -- ms =
        -- abs <| remainderBy (truncate time.second) dur
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
        div [] [ br [] [], span (L.processedBytes { bytes = formatBytes p.max, dur = toFloat p.durationMillis / 1000 }) [] ]

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


viewDate : Time.Zone -> Posix -> Html msg
viewDate tz d =
    span [ title <| ISO8601.toString <| ISO8601.fromPosix d ]
        [ text <| posixToString tz d ]


posixToString : Time.Zone -> Posix -> String
posixToString tz d =
    -- ([ Time.toYear tz d |> String.fromInt
    ([ Time.toMonth tz d |> monthToString
     , Time.toDay tz d |> String.fromInt |> String.padLeft 2 '0'
     ]
        -- |> String.join "/"
        |> String.join " "
    )
        ++ " "
        ++ ([ Time.toHour tz d
            , Time.toMinute tz d

            -- , Time.toSecond tz d
            ]
                |> List.map (String.fromInt >> String.padLeft 2 '0')
                |> String.join ":"
           )


monthToString : Time.Month -> String
monthToString m =
    case m of
        Time.Jan ->
            "Jan"

        Time.Feb ->
            "Feb"

        Time.Mar ->
            "Mar"

        Time.Apr ->
            "Apr"

        Time.May ->
            "May"

        Time.Jun ->
            "Jun"

        Time.Jul ->
            "Jul"

        Time.Aug ->
            "Aug"

        Time.Sep ->
            "Sep"

        Time.Oct ->
            "Oct"

        Time.Nov ->
            "Nov"

        Time.Dec ->
            "Dec"


viewSideAreaName : QueryDict -> Instance -> Html msg
viewSideAreaName query instance =
    let
        label =
            viewInstance query instance
    in
    case Instance.worldArea instance of
        Nothing ->
            label

        Just w ->
            if Datamine.isMap w then
                if w.isLabyrinth || w.isLabTrial then
                    span [] [ label ]

                else
                    span [] [ Icon.zana, span [ L.sideAreaZana ] [], text " (", label, text ")" ]

            else if w.isVaalArea then
                span [] [ Icon.vaal, span [ L.sideAreaVaal ] [], text " (", label, text ")" ]

            else if w.isLabTrial then
                span [] [ Icon.labTrial, span [ L.sideAreaTrial ] [], text " (", label, text ")" ]

            else if w.isAbyssalDepths then
                span [] [ Icon.abyss, label ]

            else
                label


maskedText : String -> Html msg
maskedText str =
    -- This text is hidden on the webpage, but can be copypasted. Useful for formatting shared text.
    span [ style "opacity" "0", style "font-size" "0", style "white-space" "pre" ] [ text str ]


selfUrl =
    "https://mapwatch.erosson.org"


viewHeader : OkModel -> Html msg
viewHeader model =
    div []
        [ h1 [ class "title" ]
            [ maskedText "["
            , text " "

            -- , a [ href "./" ] [ Icon.fas "tachometer-alt", text " Mapwatch" ]
            , a [ L.navHeader, Route.href model.query Route.Timer ] []
            , maskedText <| "](" ++ selfUrl ++ ")"
            ]
        , small []
            [ text " "
            , span [ L.navSubheader ] []
            , case model.flags.electronFlags |> Maybe.map .version of
                Nothing ->
                    text ""

                Just version ->
                    span [] [ text " - ", a [ target "_blank", Route.appReleasesHref ] [ text "v", text version ] ]
            ]
        ]
