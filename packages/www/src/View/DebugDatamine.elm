module View.DebugDatamine exposing (view)

import Array exposing (Array)
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Mapwatch.Datamine as Datamine exposing (Datamine, WorldArea)
import Route.QueryDict as QueryDict exposing (QueryDict)
import Set exposing (Set)
import View.Drops
import View.Icon


view : QueryDict -> Datamine -> Html msg
view query datamine =
    div []
        [ viewBackendErrors datamine
        , viewWorldAreas query datamine
        , viewNPCTexts datamine
        ]


viewBackendErrors : Datamine -> Html msg
viewBackendErrors datamine =
    let
        langs =
            Datamine.langs datamine

        viewBackendError : String -> ( String, String ) -> Html msg
        viewBackendError langName ( id, text_ ) =
            [ langName, id, text_ ]
                |> List.map (\s -> td [] [ text s ])
                |> tr []
    in
    table []
        [ thead []
            [ th [] [ text "Lang" ]
            , th [] [ text "Id" ]
            , th [] [ text "Text" ]
            ]
        , tbody []
            (datamine
                |> Datamine.langs
                |> List.concatMap
                    (\lang ->
                        lang.index.backendErrors
                            |> Dict.toList
                            |> List.map (viewBackendError lang.name)
                    )
            )
        ]


viewWorldAreas : QueryDict -> Datamine -> Html msg
viewWorldAreas query datamine =
    let
        langs =
            Datamine.langs datamine
    in
    table []
        [ thead []
            ([ th [] []
             , th [] [ text "Id" ]
             , th [] [ text "Wiki" ]
             , th [] [ text "Tags" ]
             , th [] [ text "Region" ]
             , th [] [ text "Tier" ]
             , th [] [ text "Drops" ]
             ]
                ++ List.map (\l -> th [] [ text l.name ]) langs
            )
        , tbody []
            (datamine.worldAreas
                |> Array.toList
                |> List.map
                    (\w ->
                        tr []
                            ([ td [ style "min-width" "1em", style "height" "1em" ]
                                (case Datamine.imgSrc { isBlightedMap = False, heistNpcs = Set.empty } w of
                                    Nothing ->
                                        [ text "" ]

                                    Just path ->
                                        [ img [ style "width" "100%", style "height" "100%", src path ] [] ]
                                )
                             , td [] [ text w.id ]
                             , td [] [ a [ target "_blank", href <| Datamine.wikiUrl datamine w ] [ text <| Datamine.wikiPath datamine w ] ]
                             , td [] [ text <| String.join ", " <| viewTags w ]
                             , td [] [ View.Icon.region (Just w), text <| Maybe.withDefault Datamine.defaultAtlasRegion w.atlasRegion ]
                             , td [] [ w |> Datamine.tier |> Maybe.map String.fromInt |> Maybe.withDefault "" |> text ]
                             , td [] [ View.Drops.view query datamine w ]
                             ]
                                ++ List.map (\l -> td [] [ text <| Maybe.withDefault "???" <| Dict.get w.id l.index.worldAreas ]) langs
                            )
                    )
            )
        ]


viewTags : WorldArea -> List String
viewTags w =
    [ ifMaybe w.isTown "Town"
    , ifMaybe (Datamine.isHeistTown w) "HeistTown"
    , ifMaybe w.isHideout "Hideout"
    , ifMaybe w.isMapArea "Map"
    , ifMaybe w.isUniqueMapArea "UniqueMap"
    , ifMaybe w.isLabTrial "LabTrial"
    , ifMaybe w.isLabyrinth "Labyrinth"
    , ifMaybe (Datamine.isHeistMap w) "HeistMap"
    ]
        |> List.filterMap identity


viewNPCTexts : Datamine -> Html msg
viewNPCTexts datamine =
    table []
        [ thead []
            [ th [] [ text "NPC Id" ]
            , th [] [ text "Text Id" ]
            , th [] [ text "Full dialogue" ]
            ]
        , tbody []
            (datamine.npcText
                |> Dict.toList
                |> List.map
                    (\( dialogue, { npcName, npcId, textId } ) ->
                        tr []
                            [ td [] [ text <| npcName ++ " (" ++ npcId ++ ")" ]
                            , td [] [ text textId ]
                            , td [] [ text dialogue ]
                            ]
                    )
            )
        ]


ifMaybe : Bool -> a -> Maybe a
ifMaybe b t =
    ifval b (Just t) Nothing


ifval : Bool -> a -> a -> a
ifval b t f =
    if b then
        t

    else
        f
