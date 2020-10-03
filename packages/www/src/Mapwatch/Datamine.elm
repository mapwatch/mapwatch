module Mapwatch.Datamine exposing
    ( Datamine
    , MapIconArgs
    , WorldArea
    , atlasBases
    , createDatamine_
    , decoder
    , defaultAtlasRegion
    , divCards
    , imgCdn
    , imgSrc
    , isHeistMap
    , isHeistTown
    , isMap
    , isTown
    , langIndexEmpty
    , langs
    , tier
    , wikiPath
    , wikiUrl
    , worldAreaFromName
    , worldAreaToString
    )

import Array exposing (Array)
import Dict exposing (Dict)
import Dict.Extra
import Json.Decode as D
import List.Extra
import Mapwatch.Datamine.NpcId as NpcId
import Mapwatch.Datamine.NpcText as NpcText
import Maybe.Extra
import Result.Extra
import Set exposing (Set)
import Util.String


type alias Datamine =
    { worldAreas : Array WorldArea
    , lang : Dict String Lang
    , worldAreasById : Dict String WorldArea
    , unindex : LangIndex
    , youHaveEntered : String -> Maybe String
    , atlasbase : Dict String (List String)
    , divcards : List DivCard
    , divcardsByMapName : Dict String (List DivCard)
    , npcText : Dict String NpcTextEntry
    }


type alias DivCard =
    { name : String, maps : List String, loot : String }


type alias NpcTextEntry =
    { npcId : String, textId : String, npcName : String }


type alias WorldArea =
    { id : String
    , isTown : Bool
    , isHideout : Bool

    -- use the `isMap` function instead! This is unreliable, ex. true for many boss zones and side areas
    , isMapArea : Bool
    , isUniqueMapArea : Bool
    , isVaalArea : Bool
    , isLabTrial : Bool
    , isAbyssalDepths : Bool
    , itemVisualId : Maybe String
    , atlasRegion : Maybe String
    , tiers : Maybe (List Int)
    }


type alias Lang =
    -- lang.index[id] -> text. How i18n output always works.
    { index : LangIndex

    -- lang.unindex[text] -> id. Parse logs from an arbitrary language into lang-independent ids.
    , unindex : LangIndex
    , name : String
    }


type alias LangIndex =
    { worldAreas : Dict String String
    , backendErrors : Dict String String
    , npcs : Dict String String
    , npcTextAudio : Dict String String
    }


defaultAtlasRegion : String
defaultAtlasRegion =
    "---"


tier : WorldArea -> Maybe Int
tier =
    .tiers >> Maybe.andThen (List.filter ((/=) 0) >> List.head)


worldAreaToString : Datamine -> WorldArea -> String
worldAreaToString dm world =
    dm.lang
        |> Dict.get "en"
        |> Maybe.andThen (.index >> .worldAreas >> Dict.get world.id)
        |> Maybe.withDefault world.id


worldAreaFromName : String -> Datamine -> Maybe WorldArea
worldAreaFromName name dm =
    Dict.get name dm.unindex.worldAreas
        |> Maybe.andThen (\id -> Dict.get id dm.worldAreasById)


langs : Datamine -> List Lang
langs =
    .lang >> Dict.values >> sortLangs


sortLangs : List Lang -> List Lang
sortLangs =
    -- english first, for my own personal ease of reading/debugging
    List.sortBy
        (\l ->
            ( if l.name == "en" then
                0

              else
                1
            , l.name
            )
        )


langIndexReverse : LangIndex -> LangIndex
langIndexReverse index =
    let
        invert : Dict String String -> Dict String String
        invert d =
            -- TODO: if multiple ids map to the same text, this will fail. Detect that!
            let
                ud =
                    d
                        |> Dict.toList
                        |> List.map (\( k, v ) -> ( v, k ))
                        |> Dict.fromList
            in
            --if Dict.size ud == Dict.size d then
            ud

        --else
        --    -- duplicates! which ones?
        --    Debug.todo <|
        --        "duplicate text values: "
        --            ++ (d
        --                    |> Dict.toList
        --                    |> List.map (\( k, v ) -> ( v, k ))
        --                    |> Dict.Extra.groupBy Tuple.first
        --                    |> Dict.map (\_ -> List.map Tuple.second)
        --                    |> Dict.filter (\_ v -> List.length v /= 1)
        --                    |> Dict.toList
        --                    |> List.map (\( k, v ) -> k ++ ": " ++ String.join "," v)
        --                    |> String.join "\n"
        --               )
    in
    { worldAreas = invert index.worldAreas
    , backendErrors = invert index.backendErrors
    , npcs = invert index.npcs
    , npcTextAudio = invert index.npcTextAudio
    }


langIndexEmpty : LangIndex
langIndexEmpty =
    LangIndex Dict.empty Dict.empty Dict.empty Dict.empty


langIndexUnion : List LangIndex -> LangIndex
langIndexUnion =
    let
        fold a b =
            { worldAreas = Dict.union a.worldAreas b.worldAreas
            , backendErrors = Dict.union a.backendErrors b.backendErrors
            , npcs = Dict.union a.npcs b.npcs
            , npcTextAudio = Dict.union a.npcTextAudio b.npcTextAudio
            }
    in
    List.foldr fold langIndexEmpty


imgCdn : String
imgCdn =
    "https://web.poecdn.com/image/"


type alias MapIconArgs a =
    { a | isBlightedMap : Bool }


imgSrc : MapIconArgs a -> WorldArea -> Maybe String
imgSrc args w =
    w.itemVisualId
        |> Maybe.map
            (String.replace ".dds" ".png"
                >> (\path ->
                        imgCdn
                            ++ path
                            ++ "?w=1&h=1&scale=1&mn=6&mt="
                            ++ String.fromInt (tier w |> Maybe.withDefault 0)
                            ++ boolQuery "&mb" args.isBlightedMap
                   )
            )


boolQuery : String -> Bool -> String
boolQuery n b =
    if b then
        n ++ "=1"

    else
        ""


isTown : WorldArea -> Bool
isTown w =
    w.isTown || isHeistTown w


isMap : WorldArea -> Bool
isMap w =
    if isTown w then
        False

    else
        case imgSrc { isBlightedMap = False } w of
            Nothing ->
                isHeistMap w

            Just _ ->
                True


isHeistTown : WorldArea -> Bool
isHeistTown w =
    w.id == "HeistHub"


isHeistMap : WorldArea -> Bool
isHeistMap w =
    -- TODO: "The Den" is both a heist boss and a campaign zone!
    String.startsWith "Heist" w.id && not (isHeistTown w) && w.id /= "HeistBoss_Twins"


wikiPath : Datamine -> WorldArea -> String
wikiPath dm w =
    dm.lang
        |> Dict.get "en"
        |> Maybe.andThen (.index >> .worldAreas >> Dict.get w.id)
        |> Maybe.map
            (\name ->
                if w.isMapArea && not w.isUniqueMapArea then
                    name ++ " Map"

                else
                    name
            )
        |> Maybe.withDefault ("Area:" ++ w.id)


wikiUrl : Datamine -> WorldArea -> String
wikiUrl dm w =
    "https://pathofexile.gamepedia.com/" ++ wikiPath dm w


atlasBases : Datamine -> WorldArea -> List String
atlasBases dm w =
    w.atlasRegion
        |> Maybe.andThen (\r -> Dict.get r dm.atlasbase)
        |> Maybe.withDefault []


divCards : Datamine -> WorldArea -> List DivCard
divCards dm w =
    case dm.lang |> Dict.get "en" |> Maybe.andThen (.index >> .worldAreas >> Dict.get w.id) of
        Nothing ->
            []

        Just name ->
            Dict.get name dm.divcardsByMapName
                |> Maybe.Extra.orElse (Dict.get (name ++ " Map") dm.divcardsByMapName)
                |> Maybe.withDefault []



-- Parsing


createDatamine : Array WorldArea -> Dict String Lang -> Dict String (List String) -> List DivCard -> Result String Datamine
createDatamine ws ls atlasBase divCards_ =
    Result.map (createDatamine_ ws ls atlasBase divCards_)
        (createNPCText ls)


createDatamine_ ws ls atlasBase divCards_ npcText =
    let
        worldAreasById =
            ws |> Array.toList |> List.map (\w -> ( w.id, w )) |> Dict.fromList

        init =
            Datamine ws
                ls
                worldAreasById
                langIndexEmpty
                (createYouHaveEntered ls)
                atlasBase
                divCards_
                -- div cards by map name
                (divCards_
                    |> List.concatMap (\c -> c.maps |> List.map (\m -> ( m, c )))
                    |> Dict.Extra.groupBy Tuple.first
                    |> Dict.map (\k -> List.map Tuple.second)
                )
                npcText
    in
    { init
        | unindex = init |> langs |> List.map .unindex |> langIndexUnion
    }


{-| Parse "You have entered {0}" messages for all languages.

This never changes, and it turns out that caching it is a very real performance
boost for LogLine parsing.

Most other lang lookups are exact matches, easy to do quickly. This one's a
special case because the area name is part of the message.

Prior to Poe 3.11.2 (ggpk bundles), this was "You have entered %1%".

-}
createYouHaveEntered : Dict String Lang -> String -> Maybe String
createYouHaveEntered lang =
    let
        strings : List String
        strings =
            lang
                |> Dict.values
                |> List.filterMap (\l -> Dict.get "EnteredArea" l.index.backendErrors)

        unwrappers : List (String -> Maybe String)
        unwrappers =
            strings
                |> List.filterMap
                    (\s ->
                        case String.split "{0}" s of
                            pre :: suf :: [] ->
                                Just (Util.String.unwrap (": " ++ pre) suf)

                            _ ->
                                Nothing
                    )
    in
    \raw ->
        unwrappers |> Util.String.mapFirst (\fn -> fn raw) Maybe.Extra.isJust |> Maybe.Extra.join


createNPCText : Dict String Lang -> Result String (Dict String NpcTextEntry)
createNPCText lang =
    lang
        |> Dict.values
        -- This sorting just makes debugging easier - shows English first - and
        -- has no real impact on production
        |> sortLangs
        |> List.reverse
        |> List.map createNPCText1
        |> Result.Extra.combine
        |> Result.map List.concat
        |> Result.map Dict.fromList


createNPCText1 : Lang -> Result String (List ( String, NpcTextEntry ))
createNPCText1 lang =
    [ createNPCTextSet lang NpcId.baran (Tuple.first >> String.startsWith "Baran")
    , createNPCTextSet lang NpcId.veritania (Tuple.first >> String.startsWith "Veritania")
    , createNPCTextSet lang NpcId.alHezmin (Tuple.first >> String.startsWith "AlHezmin")
    , createNPCTextSet lang NpcId.drox (Tuple.first >> String.startsWith "Drox")
    , createNPCTextSet lang NpcId.cassia (Tuple.first >> String.startsWith "Cassia")
    , createNPCTextSet lang NpcId.shaper (Tuple.first >> String.startsWith "Shaper")

    -- heist
    , createNPCTextSet lang NpcId.karst (Tuple.first >> String.startsWith "Karst")
    , createNPCTextSet lang NpcId.niles (Tuple.first >> String.startsWith "Niles")
    , createNPCTextSet lang NpcId.huck (Tuple.first >> String.startsWith "Huck")
    , createNPCTextSet lang NpcId.tibbs (Tuple.first >> String.startsWith "Tibbs")
    , createNPCTextSet lang NpcId.nenet (Tuple.first >> String.startsWith "Nenet")
    , createNPCTextSet lang NpcId.vinderi (Tuple.first >> String.startsWith "Vinderi")
    , createNPCTextSet lang NpcId.tortilla (Tuple.first >> String.startsWith "Tullina")
    , createNPCTextSet lang NpcId.gianna (Tuple.first >> (\s -> String.startsWith "Gianna" s || String.endsWith "Gianna" s))
    , createNPCTextSet lang NpcId.isla (Tuple.first >> String.startsWith "Isla")
    ]
        |> Result.Extra.combine
        |> Result.map List.concat



-- |> Debug.log ("npctextset-" ++ lang.name)


createNPCTextSet : Lang -> String -> (( String, String ) -> Bool) -> Result String (List ( String, NpcTextEntry ))
createNPCTextSet lang npcId npcTextFilter =
    case Dict.get npcId lang.index.npcs of
        Nothing ->
            -- Err <| "no such npc: " ++ npcId
            Ok []

        Just npcName ->
            case lang.index.npcTextAudio |> Dict.toList |> List.filter npcTextFilter of
                [] ->
                    Err <| "no npcTextAudio for npc: " ++ npcId

                npcTexts ->
                    -- TODO we probably need to localize the ": " separator!
                    npcTexts
                        |> List.map
                            (\( textId, text ) ->
                                NpcText.parse text
                                    |> Result.map (List.map (Tuple.pair textId))
                            )
                        |> Result.Extra.combine
                        |> Result.map
                            (List.concat
                                >> List.sort
                                >> List.map
                                    (\( textId, text ) ->
                                        ( npcName ++ ": " ++ text
                                        , { npcId = npcId, textId = textId, npcName = npcName }
                                        )
                                    )
                            )


decoder : D.Decoder Datamine
decoder =
    D.map4 createDatamine
        (D.at [ "datamine", "worldAreas", "data" ] worldAreasDecoder)
        (D.at [ "datamine", "lang" ] langDecoder)
        (D.at [ "wiki", "atlasbase", "data" ] atlasBaseDecoder)
        (D.at [ "wiki", "divcards", "data" ] divCardsDecoder)
        |> D.andThen resultToDecoder


atlasBaseDecoder : D.Decoder (Dict String (List String))
atlasBaseDecoder =
    D.map2 Tuple.pair
        (D.field "region" D.string)
        (D.at [ "loot", "red" ] <| D.map List.Extra.unique <| D.list D.string)
        |> D.list
        |> D.map Dict.fromList
        |> identity


divCardsDecoder : D.Decoder (List DivCard)
divCardsDecoder =
    D.map3 DivCard
        (D.field "card" D.string)
        (D.field "maps" <| D.list D.string)
        (D.at [ "loot", "text" ] D.string)
        |> D.list


resultToDecoder : Result String a -> D.Decoder a
resultToDecoder r =
    case r of
        Err err ->
            D.fail err

        Ok ok ->
            D.succeed ok


langDecoder : D.Decoder (Dict String Lang)
langDecoder =
    D.map4 LangIndex
        (D.field "worldAreas" <| D.dict D.string)
        (D.field "backendErrors" <| D.dict D.string)
        (D.field "npcs" <| D.dict D.string)
        (D.field "npcTextAudio" <| D.dict D.string)
        |> D.map (\index -> Lang index (langIndexReverse index))
        |> D.dict
        |> D.map (Dict.map (\k v -> v k))


worldAreasDecoder : D.Decoder (Array WorldArea)
worldAreasDecoder =
    D.map7 WorldArea
        -- fields by index are awkward, but positional rows use so much less bandwidth than keyed rows, even when minimized
        (D.index 0 D.string)
        (D.index 1 D.bool)
        (D.index 2 D.bool)
        (D.index 3 D.bool)
        (D.index 4 D.bool)
        (D.index 5 D.bool)
        (D.index 6 D.bool)
        |> D.andThen
            (\w ->
                D.map4 w
                    (D.index 7 D.bool)
                    (D.index 8 (D.maybe D.string))
                    (D.index 9 (D.maybe D.string))
                    (D.index 10 (D.maybe (D.list D.int)))
            )
        |> D.array
