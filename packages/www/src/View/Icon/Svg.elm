module View.Icon.Svg exposing (RegionStatus(..), Regions, applyRegionName, empty, init, regions)

import Html exposing (Html)
import Svg as S exposing (..)
import Svg.Attributes as A exposing (..)


type alias Regions =
    { topLeftOutside : Maybe RegionStatus
    , topLeftInside : Maybe RegionStatus
    , topRightOutside : Maybe RegionStatus
    , topRightInside : Maybe RegionStatus
    , bottomLeftOutside : Maybe RegionStatus
    , bottomLeftInside : Maybe RegionStatus
    , bottomRightOutside : Maybe RegionStatus
    , bottomRightInside : Maybe RegionStatus
    }


type RegionStatus
    = Selected
    | Sighted
    | Unsighted
    | Baran
    | Veritania
    | AlHezmin
    | Drox


init : Maybe RegionStatus -> Regions
init s =
    Regions s s s s s s s s


empty : Regions
empty =
    init Nothing


applyRegionName : String -> Maybe RegionStatus -> Regions -> Regions
applyRegionName name status rs =
    case name of
        "Haewark Hamlet" ->
            { rs | topLeftOutside = status }

        "Tirn's End" ->
            { rs | topLeftInside = status }

        "Lex Ejoris" ->
            { rs | topRightOutside = status }

        "Lex Proxima" ->
            { rs | topRightInside = status }

        "New Vastir" ->
            { rs | bottomLeftOutside = status }

        "Glennach Cairns" ->
            { rs | bottomLeftInside = status }

        "Lira Arthain" ->
            { rs | bottomRightOutside = status }

        "Valdo's Rest" ->
            { rs | bottomRightInside = status }

        _ ->
            rs


regions : Regions -> Html msg
regions r =
    svg [ class "icon-region", viewBox "0 0 2 2" ]
        [ polygon [ points "0,0 1,0 0,1", class "outer", focus r.topLeftOutside ] []
        , polygon [ points "1,1 1,0 0,1", class "inner", focus r.topLeftInside ] []
        , polygon [ points "2,0 1,0 2,1", class "outer", focus r.topRightOutside ] []
        , polygon [ points "1,1 1,0 2,1", class "inner", focus r.topRightInside ] []
        , polygon [ points "0,2 1,2 0,1", class "outer", focus r.bottomLeftOutside ] []
        , polygon [ points "1,1 1,2 0,1", class "inner", focus r.bottomLeftInside ] []
        , polygon [ points "2,2 1,2 2,1", class "outer", focus r.bottomRightOutside ] []
        , polygon [ points "1,1 1,2 2,1", class "inner", focus r.bottomRightInside ] []
        ]


focus : Maybe RegionStatus -> S.Attribute msg
focus status =
    case status of
        Just Selected ->
            class "focus"

        Just Sighted ->
            class "sighted"

        Just Unsighted ->
            class "unsighted"

        Just Baran ->
            class "focus focus-baran"

        Just Veritania ->
            class "focus focus-veritania"

        Just AlHezmin ->
            class "focus focus-alhezmin"

        Just Drox ->
            class "focus focus-drox"

        _ ->
            class "blur"
