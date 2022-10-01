module Mapwatch.BossEntry exposing
    ( BossEntry(..)
    , DeathlessData
    , LogoutlessData
    , Progress
    , VictoryData
    , VisitedData
    , deathlessData
    , isDeathless
    , isDeathlessExact
    , isLogoutless
    , isUnvisited
    , isVictory
    , isVictoryExact
    , isVisited
    , isVisitedExact
    , jsonDecode
    , jsonEncode
    , logoutlessData
    , mergeList
    , mergePair
    , progress
    , progressList
    , victoryData
    , visitedData
    )

import Json.Decode as D
import Json.Encode as E
import Maybe.Extra
import Time exposing (Posix)


type BossEntry
    = Unvisited
    | Visited VisitedData
    | Victory VictoryData
    | Deathless DeathlessData
    | Logoutless LogoutlessData


type alias VisitedData =
    { achievedAt : Posix }


type alias VictoryData =
    { achievedAt : Posix, count : Int, visited : VisitedData }


type alias DeathlessData =
    { achievedAt : Posix, victory : VictoryData }


type alias LogoutlessData =
    { achievedAt : Posix, deathless : DeathlessData }


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
                            { victory_
                                | visited = visited
                                , count = (a |> victoryData |> Maybe.Extra.unwrap 0 .count) + (b |> victoryData |> Maybe.Extra.unwrap 0 .count)
                            }
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


mergeData : Maybe { d | achievedAt : Posix } -> Maybe { d | achievedAt : Posix } -> Maybe { d | achievedAt : Posix }
mergeData ma mb =
    case ( ma, mb ) of
        ( Just a, Just b ) ->
            Just
                { a | achievedAt = min (Time.posixToMillis a.achievedAt) (Time.posixToMillis b.achievedAt) |> Time.millisToPosix }

        ( Nothing, b ) ->
            b

        ( a, Nothing ) ->
            a


mergeList : List BossEntry -> BossEntry
mergeList =
    List.foldl mergePair Unvisited



-- json encode, decode


jsonEncode : BossEntry -> D.Value
jsonEncode e =
    case e of
        Unvisited ->
            [ E.string "unvisited" ]
                |> E.list identity

        Visited d ->
            E.string "visited"
                :: jsonEncodeVisited d
                |> E.list identity

        Victory d ->
            E.string "victory"
                :: jsonEncodeVictory d
                |> E.list identity

        Deathless d ->
            E.string "deathless"
                :: jsonEncodeDeathless d
                |> E.list identity

        Logoutless d ->
            E.string "logoutless"
                :: jsonEncodeLogoutless d
                |> E.list identity


jsonEncodeVisited : VisitedData -> List D.Value
jsonEncodeVisited d =
    [ d.achievedAt |> jsonEncodePosix
    ]


jsonEncodeVictory : VictoryData -> List D.Value
jsonEncodeVictory d =
    (d.visited |> jsonEncodeVisited)
        ++ [ d.achievedAt |> jsonEncodePosix
           , d.count |> E.int
           ]


jsonEncodeDeathless : DeathlessData -> List D.Value
jsonEncodeDeathless d =
    (d.victory |> jsonEncodeVictory)
        ++ [ d.achievedAt |> jsonEncodePosix
           ]


jsonEncodeLogoutless : LogoutlessData -> List D.Value
jsonEncodeLogoutless d =
    (d.deathless |> jsonEncodeDeathless)
        ++ [ d.achievedAt |> jsonEncodePosix
           ]


jsonEncodePosix : Posix -> D.Value
jsonEncodePosix =
    Time.posixToMillis >> E.int


jsonDecode : D.Decoder BossEntry
jsonDecode =
    D.andThen
        (\type_ ->
            case type_ of
                "unvisited" ->
                    Unvisited |> D.succeed

                "visited" ->
                    jsonDecodeVisited |> D.map Visited

                "victory" ->
                    jsonDecodeVictory |> D.map Victory

                "deathless" ->
                    jsonDecodeDeathless |> D.map Deathless

                "logoutless" ->
                    jsonDecodeLogoutless |> D.map Logoutless

                _ ->
                    "unrecognized type: " ++ type_ |> D.fail
        )
        (D.index 0 D.string)


jsonDecodeVisited : D.Decoder VisitedData
jsonDecodeVisited =
    D.map VisitedData
        (D.index 1 jsonDecodePosix)


jsonDecodeVictory : D.Decoder VictoryData
jsonDecodeVictory =
    D.map3 VictoryData
        (D.index 2 jsonDecodePosix)
        (D.index 3 D.int)
        jsonDecodeVisited


jsonDecodeDeathless : D.Decoder DeathlessData
jsonDecodeDeathless =
    D.map2 DeathlessData
        (D.index 4 jsonDecodePosix)
        jsonDecodeVictory


jsonDecodeLogoutless : D.Decoder LogoutlessData
jsonDecodeLogoutless =
    D.map2 LogoutlessData
        (D.index 5 jsonDecodePosix)
        jsonDecodeDeathless


jsonDecodePosix : D.Decoder Posix
jsonDecodePosix =
    D.int |> D.map Time.millisToPosix
