module View.Drops exposing (empty, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Localization.Mapwatch as L
import Mapwatch.Datamine as Datamine exposing (Datamine, WorldArea)
import Route.Feature as Feature
import Route.QueryDict exposing (QueryDict)
import View.Icon


empty : Html msg
empty =
    details [ style "display" "none" ] [ summary [] [] ]


view : QueryDict -> Datamine -> WorldArea -> Html msg
view query dm w =
    if not <| Feature.isActive Feature.Drops query then
        empty

    else
        case ( Datamine.atlasBases dm w, Datamine.divCards dm w ) of
            ( [], [] ) ->
                -- instead of removing the element, this preserves its open/closed state
                empty

            ( ab, divs ) ->
                details []
                    [ summary (L.timerDrops { regionalItems = toFloat <| List.length ab, divs = toFloat <| List.length divs }) []
                    , ul [ class "world-area-drops" ]
                        ((ab
                            |> List.map
                                (\b ->
                                    li []
                                        [ a [ target "_blank", href ("https://pathofexile.gamepedia.com/" ++ b) ]
                                            [ text b ]
                                        ]
                                )
                         )
                            ++ (divs
                                    |> List.map
                                        (\card ->
                                            li []
                                                [ a [ target "_blank", href ("https://pathofexile.gamepedia.com/" ++ card.name) ]
                                                    [ View.Icon.divCard, text card.name ]
                                                , text " ("
                                                , text card.loot
                                                , text ")"
                                                ]
                                        )
                               )
                        )
                    ]
