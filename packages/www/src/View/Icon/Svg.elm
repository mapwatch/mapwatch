module View.Icon.Svg exposing (RegionStatus(..), Regions, applyRegionName, empty, init, regions)

import Html exposing (Html)
import Svg as S exposing (..)
import Svg.Attributes as A exposing (..)


type alias Regions =
    { topLeft : Maybe RegionStatus
    , topRight : Maybe RegionStatus
    , bottomLeft : Maybe RegionStatus
    , bottomRight : Maybe RegionStatus
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
    Regions s s s s


empty : Regions
empty =
    init Nothing


applyRegionName : String -> Maybe RegionStatus -> Regions -> Regions
applyRegionName name status rs =
    case name of
        "Haewark Hamlet" ->
            { rs | topLeft = status }

        "Glennach Cairns" ->
            { rs | bottomLeft = status }

        "Lira Arthain" ->
            { rs | bottomRight = status }

        "Valdo's Rest" ->
            { rs | topRight = status }

        -- legacy
        -- "Tirn's End" ->
        --     { rs | topLeft = status }
        -- "Lex Ejoris" ->
        --     { rs | topRight = status }
        -- "Lex Proxima" ->
        --     { rs | topRight = status }
        -- "New Vastir" ->
        --     { rs | bottomLeft = status }

        _ ->
            rs


regions : Regions -> Html msg
regions r =
    svg [ class "icon-region", viewBox "0 0 2 2" ]
        [ polygon [ points "0,0 2,0 2,2 0,2", class "border" ] []

        , polygon [ points "0,0 1,0 1,1 0,1", class "outer", focus r.topLeft ] []
        , polygon [ points "2,0 1,0 1,1 2,1", class "outer", focus r.topRight ] []
        , polygon [ points "0,2 1,2 1,1 0,1", class "outer", focus r.bottomLeft ] []
        , polygon [ points "2,2 1,2 1,1 2,1", class "outer", focus r.bottomRight ] []
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
