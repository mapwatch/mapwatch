module Mapwatch.Datamine exposing
    ( Datamine
    , WorldArea
    , decoder
    , imgCdn
    , imgSrc
    , isMap
    , langs
    , tier
    , worldAreaFromName
    , worldAreaToString
    )

import Array exposing (Array)
import Dict exposing (Dict)
import Dict.Extra
import Json.Decode as D
import Set exposing (Set)


type alias Datamine =
    { worldAreas : Array WorldArea
    , lang : Dict String Lang
    , worldAreasById : Dict String WorldArea
    , unindex : LangIndex
    }


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
    }


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
    .lang
        >> Dict.values
        -- english first, for my own personal ease of reading/debugging
        >> List.sortBy
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
    }


langIndexEmpty : LangIndex
langIndexEmpty =
    LangIndex Dict.empty Dict.empty


langIndexUnion : List LangIndex -> LangIndex
langIndexUnion =
    let
        fold a b =
            { worldAreas = Dict.union a.worldAreas b.worldAreas
            , backendErrors = Dict.union a.backendErrors b.backendErrors
            }
    in
    List.foldr fold langIndexEmpty


imgCdn : String
imgCdn =
    "https://web.poecdn.com/image/"


imgSrc : WorldArea -> Maybe String
imgSrc w =
    w.itemVisualId |> Maybe.map (String.replace ".dds" ".png" >> (\path -> imgCdn ++ path ++ "?w=1&h=1&scale=1&mn=6&mt=" ++ String.fromInt (tier w |> Maybe.withDefault 0)))


isMap : WorldArea -> Bool
isMap w =
    case imgSrc w of
        Nothing ->
            False

        Just _ ->
            True


createDatamine ws ls =
    let
        worldAreasById =
            ws |> Array.toList |> List.map (\w -> ( w.id, w )) |> Dict.fromList

        init =
            Datamine ws ls worldAreasById langIndexEmpty
    in
    { init | unindex = init |> langs |> List.map .unindex |> langIndexUnion }


decoder : D.Decoder Datamine
decoder =
    D.map2 createDatamine
        (D.at [ "worldAreas", "data" ] worldAreasDecoder)
        (D.at [ "lang" ] langDecoder)


langDecoder : D.Decoder (Dict String Lang)
langDecoder =
    D.map2 LangIndex
        (D.field "worldAreas" <| D.dict D.string)
        (D.field "backendErrors" <| D.dict D.string)
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
                D.map3 w
                    (D.index 7 D.bool)
                    (D.index 8 (D.maybe D.string))
                    (D.index 9 (D.maybe (D.list D.int)))
            )
        |> D.array
