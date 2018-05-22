module View.Nav exposing (view, viewDebug)

import Html as H
import Html.Attributes as A
import Html.Events as E
import Model.Route as Route exposing (Route(..))
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
viewLink active0 label href =
    let
        active =
            case active0 of
                Just (History _) ->
                    Just HistoryRoot

                _ ->
                    active0

        cls =
            if active == Just href then
                "active button disabled"
            else
                "inactive button"
    in
        H.a [ Route.href href, A.class cls ] label
