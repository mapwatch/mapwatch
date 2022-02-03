module Mapwatch.LogLine exposing
    ( Info(..)
    , Line
    , NPCSaysData
    , ParseError
    , dateLength
    , parse
    , parseErrorToString
    , positionEnd
    , positionStart
    )

{-| Parse log lines with regexes.

Elm's parsers are nicer and more precise than regexes. They are also much slower,
even when I avoid backtracking, so I'm stuck using these regexes.

-}

import Array exposing (Array)
import Dict exposing (Dict)
import Mapwatch.Datamine as Datamine exposing (Datamine)
import Mapwatch.Datamine.NpcId as NpcId
import Maybe.Extra
import Regex exposing (Regex)
import Set exposing (Set)
import Time exposing (Posix)
import Time.Extra
import Util.String


type alias ParseError =
    { raw : String, position : Int, err : String }


parseErrorToString : ParseError -> String
parseErrorToString e =
    -- Debug.toString e
    "{ err: " ++ e.err ++ ", raw: " ++ e.raw ++ " }"


type Info
    = Opening
    | ConnectingToInstanceServer String
    | YouHaveEntered String
    | NPCSays NPCSaysData
    | AFKMode Bool
    | RitualFindClosestObject


type alias NPCSaysData =
    { raw : String
    , npcId : String
    , npcName : String
    , textId : String
    }


type alias Line =
    { raw : String
    , position : Int
    , date : Posix
    , info : Info
    }


parse : Datamine -> Time.Zone -> ( Int, String ) -> Result ParseError Line
parse dm tz ( pos, raw ) =
    case parseInfo dm raw of
        Nothing ->
            Err { raw = raw, position = pos, err = "logline not recognized" }

        Just info ->
            case parseDate tz raw of
                Err err ->
                    Err { raw = raw, position = pos, err = "logline date invalid: " ++ err }

                Ok date ->
                    Ok { raw = raw, position = pos, date = date, info = info }


positionStart : Line -> Int
positionStart =
    .position


positionEnd : Line -> Int
positionEnd line =
    line.position + String.length line.raw


parseInfo : Datamine -> String -> Maybe Info
parseInfo dm raw =
    let
        info =
            String.dropLeft dateLength raw
    in
    if info == "***** LOG FILE OPENING *****" then
        Just Opening

    else
        info
            |> String.indexes "] "
            |> List.head
            |> Maybe.map (\i -> String.dropLeft (i + 2) info)
            |> Maybe.andThen
                (\body ->
                    if body == "FindClosestObject found no nearby object" then
                        Just RitualFindClosestObject

                    else
                        case Util.String.unwrap "Connecting to instance server at " "" body of
                            Just addr ->
                                ConnectingToInstanceServer addr |> Just

                            Nothing ->
                                case Dict.get body dm.npcText of
                                    Just { npcName, npcId, textId } ->
                                        NPCSays { raw = body, npcName = npcName, npcId = npcId, textId = textId }
                                            |> Just

                                    -- |> Debug.log "npcsays"
                                    Nothing ->
                                        case parseInfoEntered dm body of
                                            Nothing ->
                                                -- NPCSays, but we don't have matching NPCText.
                                                -- Usually this is because we don't care what they're saying,
                                                -- just that they're saying anything.
                                                case
                                                    body
                                                        |> String.split ":"
                                                        |> List.head
                                                        |> Maybe.andThen (\name -> Dict.get name dm.unindex.npcs |> Maybe.map (Tuple.pair name))
                                                        -- conqueror dialogue must match exactly to be processed - speaker alone isn't enough
                                                        |> Maybe.Extra.filter (\( _, npcId ) -> not <| Set.member npcId NpcId.conquerors)
                                                of
                                                    Just ( npcName, npcId ) ->
                                                        -- TODO: textId="" instead of a maybe-type is a bit sketchy
                                                        NPCSays { raw = body, npcName = npcName, npcId = npcId, textId = "" } |> Just

                                                    Nothing ->
                                                        if dm.afkModeEnabled body then
                                                            AFKMode True |> Just

                                                        else
                                                            case Dict.get (String.dropLeft 2 body) dm.unindex.backendErrors of
                                                                Just "AFKModeDisabled" ->
                                                                    AFKMode False |> Just

                                                                _ ->
                                                                    Nothing

                                            entered ->
                                                entered
                )


parseInfoEntered : Datamine -> String -> Maybe Info
parseInfoEntered dm =
    dm.youHaveEntered >> Maybe.map YouHaveEntered


{-| like "2018/05/13 16:05:37 "

I don't like regexes. We could avoid this one with String.split shenanigans, but
that's even uglier.

-}
dateRegex =
    "^(\\d{4})/(\\d{2})/(\\d{2}) (\\d{2}):(\\d{2}):(\\d{2}) " |> Regex.fromString |> Maybe.withDefault Regex.never


{-| it's the same length every time
-}
dateLength =
    String.length "2018/05/13 16:05:37 "


parseDate : Time.Zone -> String -> Result String Posix
parseDate tz raw =
    case Util.String.firstSubmatches dateRegex raw of
        Just ((Just y) :: (Just m) :: (Just d) :: (Just h) :: (Just min) :: (Just s) :: []) ->
            -- naturally, they stop at map5
            Maybe.map3 Time.Extra.Parts
                (String.toInt y)
                (String.toInt m |> Maybe.andThen (\mm -> Array.get (mm - 1) months))
                (String.toInt d)
                |> Maybe.andThen
                    (\parts ->
                        Maybe.map4 parts
                            (String.toInt h)
                            (String.toInt min)
                            (String.toInt s)
                            (Just 0)
                    )
                |> Maybe.map (Time.Extra.partsToPosix tz)
                |> Result.fromMaybe "invalid date parts"

        _ ->
            Err "invalid date format"


months : Array Time.Month
months =
    Array.fromList
        [ Time.Jan
        , Time.Feb
        , Time.Mar
        , Time.Apr
        , Time.May
        , Time.Jun
        , Time.Jul
        , Time.Aug
        , Time.Sep
        , Time.Oct
        , Time.Nov
        , Time.Dec
        ]
