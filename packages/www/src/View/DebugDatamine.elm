module View.DebugDatamine exposing (view)

import Array exposing (Array)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Mapwatch.Datamine exposing (Datamine)


view : Result String Datamine -> Html msg
view rdatamine =
    case rdatamine of
        Err err ->
            pre [] [ text err ]

        Ok datamine ->
            -- pre [] [ text <| Debug.toString datamine ]
            table []
                [ tbody []
                    (datamine.worldAreas
                        |> Array.toList
                        -- |> List.filter (\a -> a.isTown || a.isHideout || a.isMapArea || a.isUniqueMapArea)
                        |> List.map
                            (\w ->
                                tr []
                                    [ td [ style "min-width" "1em", style "height" "1em" ]
                                        (case Mapwatch.Datamine.imgSrc w of
                                            Nothing ->
                                                [ text "" ]

                                            Just path ->
                                                [ img [ style "width" "100%", style "height" "100%", src path ] [] ]
                                        )
                                    , td [] [ text w.id ]
                                    , td [] [ ifval w.isTown (text "Town") (text "") ]
                                    , td [] [ ifval w.isHideout (text "Hideout") (text "") ]
                                    , td [] [ ifval w.isMapArea (text "Map") (text "") ]
                                    , td [] [ ifval w.isUniqueMapArea (text "UniqueMap") (text "") ]
                                    ]
                            )
                    )
                ]


ifval : Bool -> a -> a -> a
ifval b t f =
    if b then
        t

    else
        f
