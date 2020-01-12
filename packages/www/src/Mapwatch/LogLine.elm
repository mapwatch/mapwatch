module Mapwatch.LogLine exposing
    ( Info(..)
    , Line
    , NPCSaysData
    , ParseError
    , parse
    , parseErrorToString
    )

{-| Parse log lines with regexes.

Elm's parsers are nicer and more precise than regexes. They are also much slower,
even when I avoid backtracking, so I'm stuck using these regexes.

-}

import Array exposing (Array)
import Dict exposing (Dict)
import Mapwatch.Datamine as Datamine exposing (Datamine)
import Maybe.Extra
import Regex exposing (Regex)
import Time exposing (Posix)
import Time.Extra
import Util.String


type alias ParseError =
    { raw : String, err : String }


parseErrorToString : ParseError -> String
parseErrorToString e =
    -- Debug.toString e
    "{ err: " ++ e.err ++ ", raw: " ++ e.raw ++ " }"


type Info
    = Opening
    | ConnectingToInstanceServer String
    | YouHaveEntered String
    | NPCSays NPCSaysData


type alias NPCSaysData =
    { raw : String, npcId : String, textId : String }


type alias Line =
    { raw : String
    , date : Posix
    , info : Info
    }


parse : Datamine -> Time.Zone -> String -> Result ParseError Line
parse dm tz raw =
    case parseInfo dm raw of
        Nothing ->
            Err { raw = raw, err = "logline not recognized" }

        Just info ->
            case parseDate tz raw of
                Err err ->
                    Err { raw = raw, err = "logline date invalid: " ++ err }

                Ok date ->
                    Ok { raw = raw, date = date, info = info }


parseInfo : Datamine -> String -> Maybe Info
parseInfo dm raw =
    let
        info =
            String.dropLeft dateLength raw
    in
    if info == "***** LOG FILE OPENING *****" then
        Just Opening

    else
        case info |> String.indexes "] " |> List.head |> Maybe.map (\i -> String.dropLeft (i + 2) info) of
            Nothing ->
                Nothing

            Just body ->
                case Util.String.unwrap "Connecting to instance server at " "" body of
                    Just addr ->
                        ConnectingToInstanceServer addr |> Just

                    Nothing ->
                        case Dict.get body dm.npcText of
                            Just ( npcId, textId ) ->
                                NPCSays { raw = body, npcId = npcId, textId = textId }
                                    |> Just

                            -- |> Debug.log "npcsays"
                            Nothing ->
                                parseInfoEntered dm body


parseInfoEntered : Datamine -> String -> Maybe Info
parseInfoEntered dm =
    dm.youHaveEntered >> Maybe.map YouHaveEntered


{-| like "2018/05/13 16:05:37"

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
