module View.Icon.Svg exposing (Region(..), emptyRegion, region)

import Html exposing (Html)
import Svg as S exposing (..)
import Svg.Attributes as A exposing (..)


type Region
    = RegionTopLeftOutside
    | RegionTopLeftInside
    | RegionTopRightOutside
    | RegionTopRightInside
    | RegionBottomLeftOutside
    | RegionBottomLeftInside
    | RegionBottomRightOutside
    | RegionBottomRightInside


maybeRegion : Maybe Region -> Html msg
maybeRegion r =
    svg [ class "icon-region", viewBox "0 0 2 2" ]
        [ polygon [ points "0,0 1,0 0,1", class "outer", class (maybeFocus RegionTopLeftOutside r) ] []
        , polygon [ points "1,1 1,0 0,1", class "inner", class (maybeFocus RegionTopLeftInside r) ] []
        , polygon [ points "2,0 1,0 2,1", class "outer", class (maybeFocus RegionTopRightOutside r) ] []
        , polygon [ points "1,1 1,0 2,1", class "inner", class (maybeFocus RegionTopRightInside r) ] []
        , polygon [ points "0,2 1,2 0,1", class "outer", class (maybeFocus RegionBottomLeftOutside r) ] []
        , polygon [ points "1,1 1,2 0,1", class "inner", class (maybeFocus RegionBottomLeftInside r) ] []
        , polygon [ points "2,2 1,2 2,1", class "outer", class (maybeFocus RegionBottomRightOutside r) ] []
        , polygon [ points "1,1 1,2 2,1", class "inner", class (maybeFocus RegionBottomRightInside r) ] []
        ]


emptyRegion : Html msg
emptyRegion =
    maybeRegion Nothing


region : Region -> Html msg
region r =
    maybeRegion (Just r)


maybeFocus : Region -> Maybe Region -> String
maybeFocus this =
    Maybe.map (focus this) >> Maybe.withDefault blurClass


focus : Region -> Region -> String
focus this focused =
    if this == focused then
        focusClass

    else
        blurClass


focusClass =
    "focus"


blurClass =
    "blur"
