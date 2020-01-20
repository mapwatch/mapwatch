module Mapwatch.Run2.Sort exposing
    ( GoalDuration(..)
    , SortDir(..)
    , SortField(..)
    , filterBetween
    , filterToday
    , goalDuration
    , groupByMap
    , isBetween
    , parseGoalDuration
    , parseSort
    , reverseSort
    , search
    , sort
    , stringifyGoalDuration
    , stringifySort
    )

import Dict exposing (Dict)
import Dict.Extra
import Duration exposing (Millis)
import Mapwatch.Datamine as Datamine exposing (Datamine)
import Mapwatch.Datamine.NpcId as NpcId exposing (NpcId)
import Mapwatch.Run2 as Run2 exposing (Run2)
import Mapwatch.Run2.Conqueror as Conqueror
import Maybe.Extra
import Regex exposing (Regex)
import Set exposing (Set)
import Time exposing (Posix)


isBetween : { a | after : Maybe Posix, before : Maybe Posix } -> Run2 -> Bool
isBetween { after, before } run =
    let
        at =
            -- Date.toTime run.last.leftAt
            Time.posixToMillis run.startedAt

        isAfter =
            Maybe.Extra.unwrap True (Time.posixToMillis >> (>=) at) after

        isBefore =
            Maybe.Extra.unwrap True (Time.posixToMillis >> (<=) at) before
    in
    isAfter && isBefore


filterBetween qs =
    List.filter (isBetween qs)


search : Datamine -> String -> List Run2 -> List Run2
search dm query =
    let
        pred run =
            Regex.contains
                (Regex.fromStringWith { caseInsensitive = True, multiline = False } query
                    |> Maybe.withDefault Regex.never
                )
                (searchString dm run)
    in
    List.filter pred


type SortField
    = SortDate
    | Name
    | Region
    | TimeTotal
    | TimeMap
    | TimeTown
    | TimeSide
    | Portals


sortFields =
    [ Name, Region, TimeTotal, TimeMap, TimeTown, TimeSide, Portals, SortDate ]


type SortDir
    = Asc
    | Desc


sort : Maybe String -> List Run2 -> List Run2
sort str =
    case str of
        Nothing ->
            -- skip the sort if no sort requested
            identity

        Just _ ->
            parseSort str |> (\( a, b ) -> sortParsed a b)


stringifySortField : SortField -> String
stringifySortField field =
    case field of
        Name ->
            "name"

        Region ->
            "name"

        TimeTotal ->
            "totalt"

        TimeMap ->
            "mapt"

        TimeTown ->
            "townt"

        TimeSide ->
            "sidet"

        Portals ->
            "portals"

        SortDate ->
            "date"


sortFieldByString : Dict String SortField
sortFieldByString =
    sortFields
        |> List.map (\f -> ( stringifySortField f, f ))
        |> Dict.fromList


parseSortField : String -> SortField
parseSortField str =
    Maybe.withDefault SortDate <| Dict.get str sortFieldByString


parseSort : Maybe String -> ( SortField, SortDir )
parseSort str0 =
    case String.uncons <| Maybe.withDefault "" str0 of
        Just ( '+', str ) ->
            ( parseSortField str, Asc )

        Just ( '-', str ) ->
            ( parseSortField str, Desc )

        _ ->
            let
                field =
                    parseSortField (Maybe.withDefault "" str0)
            in
            ( field
              -- date sorts desc by default, but names feel better asc (a-z), and durations feel better asc (fastest-slowest)
              -- but durations and
            , if field == SortDate then
                Desc

              else
                Asc
            )


reverseSort : SortDir -> SortDir
reverseSort dir =
    case dir of
        Asc ->
            Desc

        Desc ->
            Asc


stringifySort : SortField -> Maybe SortDir -> String
stringifySort field dir =
    let
        d =
            case dir of
                Nothing ->
                    ""

                Just Asc ->
                    "+"

                Just Desc ->
                    "-"
    in
    d ++ stringifySortField field


sortParsed : SortField -> SortDir -> List Run2 -> List Run2
sortParsed field dir runs =
    -- optimize the common, default case, which conveniently is the default list order.
    -- Same result as letting the else-branch run, but no sort cpu needed.
    if field == SortDate && dir == Desc then
        runs

    else
        runs
            |> (case field of
                    SortDate ->
                        -- .last >> .leftAt >> Date.toTime |> List.sortBy
                        -- already sorted by date-descending!
                        List.reverse

                    Name ->
                        List.sortBy (.address >> .zone)

                    Region ->
                        List.sortBy
                            (.address
                                >> .worldArea
                                >> Maybe.andThen .atlasRegion
                                >> Maybe.withDefault Datamine.defaultAtlasRegion
                            )

                    TimeTotal ->
                        List.sortBy (.duration >> .all)

                    TimeMap ->
                        List.sortBy (.duration >> .mainMap)

                    TimeTown ->
                        List.sortBy (.duration >> .town)

                    TimeSide ->
                        List.sortBy (.duration >> .sides)

                    Portals ->
                        List.sortBy .portals
               )
            |> (if dir == Desc then
                    List.reverse

                else
                    identity
               )



--filteredDuration : (Visit -> Bool) -> Run2 -> Millis
--filteredDuration pred run =
--    run.visits
--        |> List.filter pred
--        |> List.map Visit.duration
--        |> List.sum


bestDuration : (Run2 -> Millis) -> List Run2 -> Maybe Millis
bestDuration which =
    List.map which >> List.minimum


filterToday : Time.Zone -> Posix -> List Run2 -> List Run2
filterToday zone now =
    let
        ymd date =
            ( Time.toYear zone date, Time.toMonth zone date, Time.toDay zone date )

        pred run =
            ymd now == ymd run.updatedAt
    in
    List.filter pred


groupByMap : List Run2 -> Dict.Dict String (List Run2)
groupByMap =
    List.filter (.isBlightedMap >> not)
        >> Dict.Extra.groupBy (.address >> .zone)


type GoalDuration
    = SessionBest
    | AllTimeBest
    | SessionMean
    | AllTimeMean
    | Fixed Millis
    | NoGoal


{-| Determine your time goal for a run, based on other runs of the same map
-}
goalDuration : GoalDuration -> { session : List Run2, allTime : List Run2 } -> Run2 -> Maybe Millis
goalDuration goal { session, allTime } run =
    let
        aggregate : List Run2 -> Run2.Aggregate
        aggregate =
            List.filter (\r -> r.address.zone == run.address.zone) >> Run2.aggregate
    in
    case goal of
        SessionBest ->
            (aggregate session).best.all

        AllTimeBest ->
            (aggregate allTime).best.all

        SessionMean ->
            Just (aggregate session).mean.duration.all

        AllTimeMean ->
            Just (aggregate allTime).mean.duration.all

        Fixed t ->
            Just t

        NoGoal ->
            Nothing


stringifyGoalDuration : GoalDuration -> Maybe String
stringifyGoalDuration goal =
    case goal of
        SessionBest ->
            Just "best-session"

        AllTimeBest ->
            Just "best"

        SessionMean ->
            Just "mean-session"

        AllTimeMean ->
            Just "mean"

        Fixed ms ->
            Just <| String.fromInt ms

        NoGoal ->
            Nothing


parseFixedGoalDuration : String -> Maybe Millis
parseFixedGoalDuration str =
    -- TODO rewrite me with elm/parser, as evancz recommends everywhere
    case str |> String.split ":" |> List.map String.toInt of
        (Just s) :: [] ->
            -- First possible format: plain number of seconds; "300"
            Just <| s * Duration.second

        (Just m) :: (Just s) :: [] ->
            -- Second possible format: "5:00"
            if s < 60 then
                Just <| m * Duration.minute + s * Duration.second

            else
                Nothing

        _ ->
            -- third possible format: "5m 1s"; "5m"; "300s"
            let
                parsed =
                    str
                        |> Regex.findAtMost 1 (Regex.fromString "([0-9\\.]+m)?\\s*([0-9\\.]+s)?" |> Maybe.withDefault Regex.never)
                        |> List.head
                        |> Maybe.Extra.unwrap [] .submatches
                        |> List.map (Maybe.andThen <| String.slice 0 -1 >> String.toInt)
            in
            case parsed of
                [ Nothing, Nothing ] ->
                    Nothing

                [ m, s ] ->
                    Just <| Maybe.withDefault 0 m * Duration.minute + Maybe.withDefault 0 s * Duration.second

                _ ->
                    Nothing


parseGoalDuration : Maybe String -> GoalDuration
parseGoalDuration =
    Maybe.Extra.unwrap NoGoal <|
        \goal ->
            case parseFixedGoalDuration goal of
                Just t ->
                    Fixed t

                Nothing ->
                    case goal of
                        "best-session" ->
                            SessionBest

                        "best" ->
                            AllTimeBest

                        "mean-session" ->
                            SessionMean

                        "mean" ->
                            AllTimeMean

                        "none" ->
                            NoGoal

                        _ ->
                            NoGoal


npcName : NpcId -> Datamine -> Maybe String
npcName id dm =
    Dict.get "en" dm.lang
        |> Maybe.andThen (\l -> Dict.get id l.index.npcs)


searchString : Datamine -> Run2 -> String
searchString dm r =
    [ Just r.address.zone
    , if r.isBlightedMap then
        Just "Blighted"

      else
        Nothing
    , r.address.worldArea
        |> Maybe.Extra.unwrap (Just Datamine.defaultAtlasRegion) .atlasRegion
    , r.conqueror |> Maybe.andThen (\( cid, _ ) -> npcName (Conqueror.npcFromId cid) dm)
    ]
        ++ (r.npcs |> Set.toList |> List.map (\id -> npcName id dm))
        |> List.filterMap identity
        |> String.join "\n"
