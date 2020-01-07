module Mapwatch.Datamine exposing (AtlasNode, AtlasRegion, Datamine, WorldArea, atlasRegion, decoder)

import Array exposing (Array)
import Dict exposing (Dict)
import Json.Decode as D
import Set exposing (Set)


type alias Datamine =
    { atlasRegions : Array AtlasRegion
    , atlasNodes : Array AtlasNode
    , worldAreas : Array WorldArea
    }


type alias WorldArea =
    { id : String
    , name : String
    , isTown : Bool
    , isHideout : Bool
    , isMapArea : Bool
    , rowId : Int
    , atlasNode : Maybe AtlasNode
    }


type alias AtlasNode =
    { worldAreasKey : Int
    , tiers : List Int
    , ddsFile : String
    , atlasRegion : AtlasRegion
    }


type AtlasRegion
    = AtlasRegion String


type alias RawAtlasNode =
    { worldAreasKey : Int
    , atlasRegionsKey : Int
    , tiers : List Int
    , ddsFile : String
    }


type alias RawWorldArea =
    { id : String
    , name : String
    , isTown : Bool
    , isHideout : Bool
    , isMapArea : Bool
    , rowId : Int
    }


atlasRegion : AtlasRegion -> String
atlasRegion (AtlasRegion r) =
    r


decoder : D.Decoder Datamine
decoder =
    D.map3 postprocess
        (D.at [ "WorldAreas.dat", "data" ] rawWorldAreasDecoder)
        (D.at [ "AtlasNode.dat", "data" ] rawAtlasNodesDecoder)
        (D.at [ "AtlasRegions.dat", "data" ] atlasRegionsDecoder)
        |> D.andThen
            (\r ->
                case r of
                    Err err ->
                        D.fail err

                    Ok ok ->
                        D.succeed ok
            )


postprocess : Array RawWorldArea -> Array RawAtlasNode -> Array AtlasRegion -> Result String Datamine
postprocess rawWorldAreas rawAtlasNodes atlasRegions =
    rawAtlasNodes
        |> Array.map
            (\a ->
                Array.get a.atlasRegionsKey atlasRegions
                    |> Result.fromMaybe "no such region"
                    |> Result.map (AtlasNode a.worldAreasKey a.tiers a.ddsFile)
            )
        |> resultCombineArray
        |> Result.andThen
            (\atlasNodes ->
                let
                    atlasNodesByWorld : Dict Int AtlasNode
                    atlasNodesByWorld =
                        atlasNodes
                            |> Array.toList
                            |> List.map (\a -> ( a.worldAreasKey, a ))
                            |> Dict.fromList
                in
                rawWorldAreas
                    |> Array.map
                        (\w ->
                            let
                                atlasNode : Maybe AtlasNode
                                atlasNode =
                                    Dict.get w.rowId atlasNodesByWorld
                            in
                            --if w.isMapArea && atlasNode == Nothing then
                            -- TODO: Many unique maps have no atlas node! Oops!
                            -- Err <| w.id ++ " (" ++ w.name ++ "): isMapArea=true, but no atlas node found"
                            -- else
                            if not w.isMapArea && atlasNode /= Nothing then
                                Err <| w.id ++ " (" ++ w.name ++ "): isMapArea=false, but found an atlas node"

                            else
                                Ok
                                    { id = w.id
                                    , name = w.name
                                    , isTown = w.isTown
                                    , isHideout = w.isHideout
                                    , isMapArea = w.isMapArea
                                    , rowId = w.rowId
                                    , atlasNode = atlasNode
                                    }
                        )
                    |> resultCombineArray
                    |> Result.map (Datamine atlasRegions atlasNodes)
            )


resultCombineArray : Array (Result e a) -> Result e (Array a)
resultCombineArray =
    Array.foldl (Result.map2 Array.push) (Ok Array.empty)


rawWorldAreasDecoder : D.Decoder (Array RawWorldArea)
rawWorldAreasDecoder =
    D.map5 RawWorldArea
        -- fields by index are awkward, but positional rows use so much less bandwidth than keyed rows, even when minimized
        (D.index 0 D.string)
        (D.index 1 D.string)
        (D.index 2 D.bool)
        (D.index 3 D.bool)
        (D.index 4 D.bool)
        |> D.array
        -- last parameter, id, is list index. This is why we can't have a singular worldAreaDecoder
        |> D.map (Array.indexedMap (\i v -> v i))


atlasRegionsDecoder : D.Decoder (Array AtlasRegion)
atlasRegionsDecoder =
    D.index 0 D.string
        |> D.map AtlasRegion
        |> D.array


rawAtlasNodesDecoder : D.Decoder (Array RawAtlasNode)
rawAtlasNodesDecoder =
    D.map4 RawAtlasNode
        -- fields by index are awkward, but positional rows use so much less bandwidth than keyed rows, even when minimized
        (D.index 0 D.int)
        (D.index 1 D.int)
        -- list of tiers per watchstone
        (D.map5 (\a b c d e -> [ a, b, c, d, e ])
            (D.index 2 D.int)
            (D.index 3 D.int)
            (D.index 4 D.int)
            (D.index 5 D.int)
            (D.index 6 D.int)
        )
        (D.index 7 D.string)
        |> D.array
