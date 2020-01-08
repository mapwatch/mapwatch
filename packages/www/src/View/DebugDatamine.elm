module View.DebugDatamine exposing (view)

import Array exposing (Array)
import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Mapwatch.Datamine as Datamine exposing (Datamine, WorldArea)


view : Datamine -> Html msg
view datamine =
    let
        langs =
            Datamine.langs datamine
    in
    -- pre [] [ text <| Debug.toString datamine ]
    table []
        [ thead []
            ([ th [] []
             , th [] [ text "Id" ]
             , th [] [ text "Tags" ]
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
                                (case Datamine.imgSrc w of
                                    Nothing ->
                                        [ text "" ]

                                    Just path ->
                                        [ img [ style "width" "100%", style "height" "100%", src path ] [] ]
                                )
                             , td [] [ text w.id ]
                             , td [] [ text <| String.join ", " <| viewTags w ]
                             ]
                                ++ List.map (\l -> td [] [ text <| Maybe.withDefault "???" <| Dict.get w.id l.index.worldAreas ]) langs
                            )
                    )
            )
        ]


viewTags : WorldArea -> List String
viewTags w =
    [ ifMaybe w.isTown "Town"
    , ifMaybe w.isHideout "Hideout"
    , ifMaybe w.isMapArea "Map"
    , ifMaybe w.isUniqueMapArea "UniqueMap"
    ]
        |> List.filterMap identity


ifMaybe : Bool -> a -> Maybe a
ifMaybe b t =
    ifval b (Just t) Nothing


ifval : Bool -> a -> a -> a
ifval b t f =
    if b then
        t

    else
        f
