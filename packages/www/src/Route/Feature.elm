module Route.Feature exposing
    ( Feature(..)
    , activate
    , boolToString
    , deactivate
    , filterDefaults
    , fromString
    , getBackendName
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
    | Backend
    | HeistNpcs
    | Drops
    | LogSlice
    | AFKDuration
    | DebugLocalization


type alias QueryString =
    Dict String String


list : List Feature
list =
    [ Goals
    , Speech
    , DownloadLink
    , GSheets
    , Backend
    , HeistNpcs
    , Drops
    , LogSlice
    , AFKDuration
    , DebugLocalization
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
            FeatureConfig feature "gsheets" True

        Backend ->
            FeatureConfig feature "backend" False

        HeistNpcs ->
            FeatureConfig feature "heistNpcs" True

        Drops ->
            FeatureConfig feature "drops" True

        LogSlice ->
            FeatureConfig feature "logslice" True

        AFKDuration ->
            FeatureConfig feature "afkDuration" False

        DebugLocalization ->
            FeatureConfig feature "debugLocalization" False


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


{-| "Backend" is not a boolean feature, but this is a quick hacky way to get the behavior we want
-}
getBackendName : QueryString -> Maybe String
getBackendName =
    Dict.get "backend"
