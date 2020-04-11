module Route.Feature exposing
    ( Feature(..)
    , activate
    , boolToString
    , deactivate
    , filterDefaults
    , fromString
    , insert
    , isActive
    , list
    , set
    , string
    , toggle
    )

{-| Boolean feature switches, toggled via query string parameters.
-}

import Dict exposing (Dict)
import Maybe.Extra
import Set exposing (Set)


type alias FeatureConfig =
    { enum : Feature
    , string : String
    , default : Bool
    }


type Feature
    = Goals
    | Speech
    | DownloadLink
    | GSheets
    | ConquerorStatus
    | DeliriumEncounter


type alias QueryString =
    Dict String String


list : List Feature
list =
    [ Goals
    , Speech
    , DownloadLink
    , GSheets
    , ConquerorStatus
    , DeliriumEncounter
    ]


set : Set String
set =
    list |> List.map string |> Set.fromList


config : Feature -> FeatureConfig
config feature =
    case feature of
        Goals ->
            FeatureConfig feature "enableGoals" True

        Speech ->
            FeatureConfig feature "enableSpeech" True

        DownloadLink ->
            FeatureConfig feature "downloadLink" True

        GSheets ->
            FeatureConfig feature "gsheets" False

        ConquerorStatus ->
            FeatureConfig feature "conquerorStatus" False

        DeliriumEncounter ->
            FeatureConfig feature "deliriumEncounter" False


byString : Dict String FeatureConfig
byString =
    list |> List.map (config >> (\c -> ( c.string, c ))) |> Dict.fromList


fromString : String -> Maybe Feature
fromString s =
    Dict.get s byString |> Maybe.map .enum


string : Feature -> String
string =
    config >> .string


defaultValue : Feature -> Bool
defaultValue =
    config >> .default


stringToBool : String -> Bool
stringToBool s =
    not (s == "" || s == "0")


isActive : Feature -> QueryString -> Bool
isActive feature =
    Dict.get (string feature) >> Maybe.Extra.unwrap (defaultValue feature) stringToBool


activate : Feature -> QueryString -> QueryString
activate f d =
    insert f True d


deactivate : Feature -> QueryString -> QueryString
deactivate f d =
    insert f False d


remove : Feature -> QueryString -> QueryString
remove f =
    Dict.remove (string f)


toggle : Feature -> QueryString -> QueryString
toggle f d =
    insert f (not <| isActive f d) d


insert : Feature -> Bool -> QueryString -> QueryString
insert f b =
    if b == defaultValue f then
        remove f

    else
        b |> boolToString |> Dict.insert (string f)


boolToString : Bool -> String
boolToString b =
    if b then
        "1"

    else
        "0"


isDefault : Feature -> QueryString -> Bool
isDefault f q =
    isActive f q == defaultValue f


filterDefaults : QueryString -> QueryString
filterDefaults query =
    let
        fold f q =
            if isActive f q == defaultValue f then
                remove f q

            else
                q
    in
    List.foldl fold query list
