module View.Nav exposing (view, viewDebug)

import Html as H
import Html.Attributes as A
import Html.Events as E
import Model.Route as Route exposing (Route(..))


sourceUrl =
    "https://www.github.com/erosson/mapwatch"


viewLinks : List ( String, Route ) -> Route -> H.Html msg
viewLinks links active =
    links
        |> List.map (uncurry <| viewLink active)
        -- |> (++) [ H.a [ A.target "_blank", A.href sourceUrl ] [ maskedText " | [", H.text "Source code", maskedText <| "](" ++ sourceUrl ++ ")" ] ]
        |> (\links -> links ++ [ H.a [ A.target "_blank", A.href sourceUrl, A.class "button inactive" ] [ H.text "Source code" ] ])
        |> H.nav []


links : List ( String, Route )
links =
    [ ( "Timer", Timer )
    , ( "History", HistoryRoot )

    -- , ( "Legacy", Home )
    ]


view =
    viewLinks links


debugLinks =
    links
        ++ [ ( "Debug", Debug )
           , ( "DumpLines", DebugDumpLines )
           ]


viewDebug =
    viewLinks debugLinks


viewLink : Route -> String -> Route -> H.Html msg
viewLink active0 label href =
    let
        active =
            case active0 of
                History _ ->
                    HistoryRoot

                _ ->
                    active0

        cls =
            if active == href then
                "active button disabled"
            else
                "inactive button"
    in
        H.a [ Route.href href, A.class cls ] [ H.text label ]
