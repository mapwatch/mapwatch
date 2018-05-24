module View.Nav exposing (view, viewDebug)

import Html as H
import Html.Attributes as A
import Html.Events as E
import Model.Route as Route exposing (Route(..), HistoryParams, MapsParams)
import View.Icon as Icon


sourceUrl =
    "https://www.github.com/mapwatch/mapwatch"


viewLinks : List ( List (H.Html msg), Route ) -> Maybe Route -> H.Html msg
viewLinks links active =
    links
        |> List.map (uncurry <| viewLink active)
        -- |> (++) [ H.a [ A.target "_blank", A.href sourceUrl ] [ maskedText " | [", H.text "Source code", maskedText <| "](" ++ sourceUrl ++ ")" ] ]
        |> (\links ->
                links
                    ++ [ H.a [ A.target "_blank", A.href sourceUrl, A.class "button inactive" ]
                            [ Icon.fas "code", H.text " Code" ]

                       -- [ fab "github", H.text " Source code" ]
                       ]
           )
        |> H.nav []


links : List ( List (H.Html msg), Route )
links =
    [ ( [ Icon.fas "stopwatch", H.text " Timer" ], Timer )
    , ( [ Icon.fas "history", H.text " History" ], HistoryRoot )
    , ( [ Icon.fas "map", H.text " Maps" ], MapsRoot )
    , ( [ Icon.fas "newspaper", H.text " Changes" ], Changelog )

    -- , ( H.span [] [H.text "Legacy"], Home )
    ]


view =
    viewLinks links


debugLinks =
    links
        ++ [ ( [ H.text "Debug" ], Debug )
           , ( [ H.text "DumpLines" ], DebugDumpLines )
           ]


viewDebug =
    viewLinks debugLinks


viewLink : Maybe Route -> List (H.Html msg) -> Route -> H.Html msg
viewLink active0 label href0 =
    let
        -- if we've typed a search query, preserve it across nav links
        searchHref : Maybe String -> Route
        searchHref search =
            case href0 of
                MapsRoot ->
                    Maps <| MapsParams search Nothing

                HistoryRoot ->
                    History <| HistoryParams 0 search Nothing

                _ ->
                    href0

        -- detect active-state for routes with queries
        ( active, href ) =
            case active0 of
                Just (History { search }) ->
                    ( Just HistoryRoot, searchHref search )

                Just (Maps { search }) ->
                    ( Just MapsRoot, searchHref search )

                _ ->
                    ( active0, href0 )

        cls =
            if active == Just href0 then
                "active button disabled"
            else
                "inactive button"
    in
        H.a [ Route.href href, A.class cls ] label
