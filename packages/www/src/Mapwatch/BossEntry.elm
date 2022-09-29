module Mapwatch.BossEntry exposing
    ( BossEntry(..)
    , Progress
    , isDeathless
    , isDeathlessExact
    , isLogoutless
    , isUnvisited
    , isVictory
    , isVictoryExact
    , isVisited
    , isVisitedExact
    , mergeList
    , mergePair
    , progress
    , progressList
    )

import Maybe.Extra
import Time exposing (Posix)


type BossEntry
    = Unvisited
    | Visited VisitedData
    | Victory VictoryData
    | Deathless DeathlessData
    | Logoutless LogoutlessData


type alias VisitedData =
    { achievedAt : Posix, count : Int }


type alias VictoryData =
    { achievedAt : Posix, count : Int, visited : VisitedData }


type alias DeathlessData =
    { achievedAt : Posix, count : Int, victory : VictoryData }


type alias LogoutlessData =
    { achievedAt : Posix, count : Int, deathless : DeathlessData }


isUnvisited : BossEntry -> Bool
isUnvisited =
    (==) Unvisited


visitedData : BossEntry -> Maybe VisitedData
visitedData s =
    case s of
        Visited d ->
            Just d

        _ ->
            s |> victoryData |> Maybe.map .visited


isVisited : BossEntry -> Bool
isVisited =
    visitedData >> Maybe.Extra.isJust


isVisitedExact : BossEntry -> Bool
isVisitedExact s =
    case s of
        Visited _ ->
            True

        _ ->
            False


victoryData : BossEntry -> Maybe VictoryData
victoryData s =
    case s of
        Victory d ->
            Just d

        _ ->
            s |> deathlessData |> Maybe.map .victory


isVictory : BossEntry -> Bool
isVictory =
    victoryData >> Maybe.Extra.isJust


isVictoryExact : BossEntry -> Bool
isVictoryExact s =
    case s of
        Victory _ ->
            True

        _ ->
            False


deathlessData : BossEntry -> Maybe DeathlessData
deathlessData s =
    case s of
        Deathless d ->
            Just d

        _ ->
            s |> logoutlessData |> Maybe.map .deathless


isDeathless : BossEntry -> Bool
isDeathless =
    deathlessData >> Maybe.Extra.isJust


isDeathlessExact : BossEntry -> Bool
isDeathlessExact s =
    case s of
        Deathless _ ->
            True

        _ ->
            False


logoutlessData : BossEntry -> Maybe LogoutlessData
logoutlessData s =
    case s of
        Logoutless d ->
            Just d

        _ ->
            Nothing


isLogoutless : BossEntry -> Bool
isLogoutless =
    logoutlessData >> Maybe.Extra.isJust


type alias Progress =
    { percent : Float, completed : Int, possible : Int }


createProgress : Int -> Int -> Progress
createProgress completed possible =
    Progress (toFloat (max 0 completed) / toFloat (max 1 possible)) completed possible


mergeProgress : List Progress -> Progress
mergeProgress ps =
    createProgress (ps |> List.map .completed |> List.sum) (ps |> List.map .possible |> List.sum)


progressList : List BossEntry -> Progress
progressList =
    List.map progress >> mergeProgress


progress : BossEntry -> Progress
progress e =
    let
        p =
            case e of
                Unvisited ->
                    0

                Visited _ ->
                    1

                Victory _ ->
                    2

                Deathless _ ->
                    3

                Logoutless _ ->
                    4
    in
    createProgress p 4


mergePair : BossEntry -> BossEntry -> BossEntry
mergePair a b =
    case mergeData (visitedData a) (visitedData b) of
        Nothing ->
            Unvisited

        Just visited ->
            case mergeData (victoryData a) (victoryData b) of
                Nothing ->
                    Visited visited

                Just victory_ ->
                    let
                        victory =
                            { victory_ | visited = visited }
                    in
                    case mergeData (deathlessData a) (deathlessData b) of
                        Nothing ->
                            Victory victory

                        Just deathless_ ->
                            let
                                deathless =
                                    { deathless_ | victory = victory }
                            in
                            case mergeData (logoutlessData a) (logoutlessData b) of
                                Nothing ->
                                    Deathless deathless

                                Just logoutless_ ->
                                    Logoutless { logoutless_ | deathless = deathless }


mergeData : Maybe { d | achievedAt : Posix, count : Int } -> Maybe { d | achievedAt : Posix, count : Int } -> Maybe { d | achievedAt : Posix, count : Int }
mergeData ma mb =
    case ( ma, mb ) of
        ( Just a, Just b ) ->
            Just
                { a
                    | count = a.count + b.count
                    , achievedAt = min (Time.posixToMillis a.achievedAt) (Time.posixToMillis b.achievedAt) |> Time.millisToPosix
                }

        ( Nothing, b ) ->
            b

        ( a, Nothing ) ->
            a


mergeList : List BossEntry -> BossEntry
mergeList =
    List.foldl mergePair Unvisited
