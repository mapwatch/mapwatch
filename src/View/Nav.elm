module View.Nav exposing (view, viewDebug)

import Html as H
import Html.Attributes as A
import Html.Events as E
import Model.Route as Route exposing (Route(..), HistoryParams)
import View.Icon as Icon


sourceUrl =
    "https://www.github.com/erosson/mapwatch"


viewLinks : List ( List (H.Html msg), Route ) -> Maybe Route -> H.Html msg
viewLinks links active =
    links
        |> List.map (uncurry <| viewLink active)
        -- |> (++) [ H.a [ A.target "_blank", A.href sourceUrl ] [ maskedText " | [", H.text "Source code", maskedText <| "](" ++ sourceUrl ++ ")" ] ]
        |> (\links ->
                links
                    ++ [ H.a [ A.target "_blank", A.href sourceUrl, A.class "button inactive" ]
                            [ Icon.fas "code-branch", H.text " Source code" ]

                       -- [ fab "github", H.text " Source code" ]
                       ]
           )
        |> H.nav []


links : List ( List (H.Html msg), Route )
links =
    [ ( [ Icon.fas "stopwatch", H.text " Timer" ], Timer )
    , ( [ Icon.fas "history", H.text " History" ], HistoryRoot )
    , ( [ Icon.fas "map", H.text " Maps" ], MapsRoot )

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
        searchHref search =
            case href0 of
                MapsRoot ->
                    Maps search

                HistoryRoot ->
                    History (HistoryParams 0 search)

                _ ->
                    href0

        ( active, href ) =
            case active0 of
                Just (History { search }) ->
                    ( Just HistoryRoot, searchHref search )

                Just (Maps search) ->
                    ( Just MapsRoot, searchHref search )

                _ ->
                    ( active0, href0 )

        cls =
            if active == Just href then
                "active button disabled"
            else
                "inactive button"
    in
        H.a [ Route.href href, A.class cls ] label
