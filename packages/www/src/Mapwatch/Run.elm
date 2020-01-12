module Mapwatch.Run exposing
    ( DurationSet
    , GoalDuration(..)
    , Run
    , SortDir(..)
    , SortField(..)
    , State(..)
    , Summary
    , bestDuration
    , current
    , duration
    , durationPerSideArea
    , durationSet
    , filterBetween
    , filterToday
    , goalDuration
    , groupByMap
    , init
    , instance
    , isBetween
    , meanDurationSet
    , parseGoalDuration
    , parseSort
    , reverseSort
    , search
    , sort
    , stateDuration
    , stateLastUpdatedAt
    , stringifyGoalDuration
    , stringifySort
    , summarize
    , tick
    , totalDurationSet
    , update
    , updateNPCText
    )

import Dict
import Dict.Extra
import Duration exposing (Millis)
import Mapwatch.Debug
import Mapwatch.Instance as Instance exposing (Instance)
import Mapwatch.LogLine as LogLine
import Mapwatch.Visit as Visit exposing (Visit)
import Maybe.Extra
import Regex
import Time


type alias Run =
    { visits : List Visit, first : Visit, last : Visit, portals : Int, instance : Instance.Address, npcSays : List LogLine.NPCSaysData }


type State
    = Empty
    | Started Time.Posix (List LogLine.NPCSaysData)
    | Running Run


init : List LogLine.NPCSaysData -> Visit -> Maybe Run
init npcSays visit =
    if Visit.isOffline visit || not (Visit.isMap visit) then
        Nothing

    else
        case visit.instance of
            Instance.MainMenu ->
                -- this will never happen, because Visit.isMap would be false above
                Nothing

            Instance.Instance i ->
                -- there's some redundancy in repeating instance here, but this guarantees it exists
                Just { first = visit, last = visit, visits = [ visit ], portals = 1, instance = i, npcSays = npcSays }


instance : Run -> Instance.Address
instance =
    .instance


search : String -> List Run -> List Run
search query =
    let
        pred run =
            Regex.contains
                (Regex.fromStringWith { caseInsensitive = True, multiline = False } query
                    |> Maybe.withDefault Regex.never
                )
                (instance run).zone
    in
    List.filter pred


type SortField
    = SortDate
    | Name
    | TimeTotal
    | TimeMap
    | TimeTown
    | TimeSide
    | Portals


sortFields =
    [ Name, TimeTotal, TimeMap, TimeTown, TimeSide, Portals, SortDate ]


type SortDir
    = Asc
    | Desc


sort : Maybe String -> List Run -> List Run
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


sortFieldByString : Dict.Dict String SortField
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


sortParsed : SortField -> SortDir -> List Run -> List Run
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
                        instance >> .zone |> List.sortBy

                    TimeTotal ->
                        duration |> List.sortBy

                    TimeMap ->
                        durationSet >> .mainMap |> List.sortBy

                    TimeTown ->
                        durationSet >> .town |> List.sortBy

                    TimeSide ->
                        durationSet >> .sides |> List.sortBy

                    Portals ->
                        .portals |> List.sortBy
               )
            |> (if dir == Desc then
                    List.reverse

                else
                    identity
               )


isBetween : { a | after : Maybe Time.Posix, before : Maybe Time.Posix } -> Run -> Bool
isBetween { after, before } run =
    let
        at =
            -- Date.toTime run.last.leftAt
            Time.posixToMillis run.first.joinedAt

        isAfter =
            Maybe.Extra.unwrap True (Time.posixToMillis >> (>=) at) after

        isBefore =
            Maybe.Extra.unwrap True (Time.posixToMillis >> (<=) at) before
    in
    isAfter && isBefore


filterBetween qs =
    List.filter (isBetween qs)


stateDuration : Time.Posix -> State -> Maybe Millis
stateDuration now state =
    case state of
        Empty ->
            Nothing

        Started at _ ->
            Just <| max 0 <| Time.posixToMillis now - Time.posixToMillis at

        Running run ->
            Just <| max 0 <| Time.posixToMillis now - Time.posixToMillis run.first.joinedAt


duration : Run -> Millis
duration v =
    max 0 <| Time.posixToMillis v.last.leftAt - Time.posixToMillis v.first.joinedAt


filteredDuration : (Visit -> Bool) -> Run -> Millis
filteredDuration pred run =
    run.visits
        |> List.filter pred
        |> List.map Visit.duration
        |> List.sum


type alias DurationSet =
    { all : Millis, town : Millis, mainMap : Millis, sides : Millis, notTown : Millis, portals : Float }


durationSet : Run -> DurationSet
durationSet run =
    let
        all =
            duration run

        town =
            filteredDuration Visit.isTown run

        notTown =
            filteredDuration (not << Visit.isTown) run

        mainMap =
            filteredDuration (\v -> v.instance == run.first.instance) run
    in
    { all = all, town = town, notTown = notTown, mainMap = mainMap, sides = notTown - mainMap, portals = toFloat run.portals }


totalDurationSet : List Run -> DurationSet
totalDurationSet runs =
    let
        durs =
            List.map durationSet runs

        sum get =
            durs |> List.map get |> List.sum
    in
    { all = sum .all, town = sum .town, notTown = sum .notTown, mainMap = sum .mainMap, sides = sum .sides, portals = sum .portals }


meanDurationSet : List Run -> DurationSet
meanDurationSet runs =
    let
        d =
            totalDurationSet runs

        n =
            List.length runs
                -- nonzero, since we're dividing. Numerator will be zero, so result is zero, that's fine.
                |> max 1
    in
    { all = d.all // n, town = d.town // n, notTown = d.notTown // n, mainMap = d.mainMap // n, sides = d.sides // n, portals = d.portals / toFloat n }


bestDuration : (DurationSet -> Millis) -> List Run -> Maybe Millis
bestDuration which runs =
    runs
        |> List.map (durationSet >> which)
        |> List.minimum


meanDuration : (DurationSet -> Millis) -> List Run -> Maybe Millis
meanDuration which runs =
    if runs == [] then
        Nothing

    else
        runs |> meanDurationSet |> which |> Just


filterToday : Time.Zone -> Time.Posix -> List Run -> List Run
filterToday zone now =
    let
        ymd date =
            ( Time.toYear zone date, Time.toMonth zone date, Time.toDay zone date )

        pred run =
            ymd now == ymd run.last.leftAt
    in
    List.filter pred


groupByMap : List Run -> Dict.Dict String (List Run)
groupByMap =
    Dict.Extra.groupBy (instance >> .zone)


type GoalDuration
    = SessionBest
    | AllTimeBest
    | SessionMean
    | AllTimeMean
    | Fixed Millis
    | NoGoal


goalDuration : GoalDuration -> { session : List Run, allTime : List Run } -> Run -> Maybe Millis
goalDuration goal runset =
    let
        foldRuns : (List Run -> Maybe Millis) -> List Run -> Dict.Dict String Millis
        foldRuns foldFn =
            groupByMap >> Dict.Extra.filterMap (always foldFn)

        key run =
            (instance run).zone
    in
    case goal of
        SessionBest ->
            let
                -- building the dict inline gives the same result, but this should be
                -- much more efficient: build it once, in a closure, instead of
                -- rebuilding every time we Dict.get. Inspecting Elm's generated JS
                -- verifies this (though, who knows what optimizations the browser does)
                dict =
                    foldRuns (bestDuration .all) runset.session
            in
            \run -> Dict.get (key run) dict

        AllTimeBest ->
            let
                dict =
                    foldRuns (bestDuration .all) runset.allTime
            in
            \run -> Dict.get (key run) dict

        SessionMean ->
            let
                dict =
                    foldRuns (meanDuration .all) runset.session
            in
            \run -> Dict.get (key run) dict

        AllTimeMean ->
            let
                dict =
                    foldRuns (meanDuration .all) runset.allTime
            in
            \run -> Dict.get (key run) dict

        Fixed t ->
            always <| Just t

        NoGoal ->
            always Nothing


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


durationPerSideArea : Run -> List ( Instance.Address, Millis )
durationPerSideArea run =
    durationPerInstance run
        |> List.filter (\( i, _ ) -> (not <| Instance.isTown i) && (i /= run.first.instance))
        |> List.filterMap
            (\( i_, d ) ->
                case i_ of
                    Instance.Instance i ->
                        Just ( i, d )

                    Instance.MainMenu ->
                        -- Debug.todo "Instance.isTown should have filtered this one"
                        Nothing
            )


durationPerInstance : Run -> List ( Instance, Millis )
durationPerInstance { visits } =
    let
        instanceToZoneKey instance_ =
            case instance_ of
                Instance.Instance i ->
                    i.zone

                Instance.MainMenu ->
                    "(none)"

        updateDurDict instance_ duration_ val0 =
            val0
                |> Maybe.withDefault ( instance_, 0 )
                |> Tuple.mapSecond ((+) duration_)
                |> Just

        foldDurs ( instance_, duration_ ) dict =
            Dict.update (instanceToZoneKey instance_) (updateDurDict instance_ duration_) dict
    in
    visits
        |> List.map (\v -> ( v.instance, Visit.duration v ))
        |> List.foldl foldDurs Dict.empty
        |> Dict.values


push : Visit -> Run -> Maybe Run
push visit run =
    if Visit.isOffline visit then
        Nothing

    else
        Just { run | last = visit, visits = visit :: run.visits }


tick : Time.Posix -> Instance.State -> State -> ( State, Maybe Run )
tick now instance_ state =
    -- go offline when time has passed since the last log entry.
    case state of
        Empty ->
            ( state, Nothing )

        Started at _ ->
            if Instance.isOffline now instance_ then
                -- we just went offline while in a map - end/discard the run
                ( Empty, Nothing )
                    |> Mapwatch.Debug.log "Run.tick: Started -> offline"

            else
                -- no changes
                ( state, Nothing )

        Running run ->
            if Instance.isOffline now instance_ then
                -- they went offline during a run. Start a new run.
                if Instance.isTown instance_.val then
                    -- they went offline in town - end the run, discarding the time in town.
                    ( Empty, Just run )
                        |> Mapwatch.Debug.log "Run.tick: Running<town> -> offline"

                else
                    -- they went offline in the map or a side area.
                    -- we can't know how much time they actually spent running before disappearing - discard the run.
                    ( Empty, Nothing )
                        |> Mapwatch.Debug.log "Run.tick: Running<not-town> -> offline"

            else
                -- no changes
                ( state, Nothing )


current : Time.Posix -> Maybe Instance.State -> State -> Maybe Run
current now minstance_ state =
    case minstance_ of
        Nothing ->
            Nothing

        Just instance_ ->
            let
                visitResult v =
                    case update instance_ (Just v) state of
                        ( _, Just run ) ->
                            Just run

                        ( Running run, _ ) ->
                            Just run

                        _ ->
                            Nothing
            in
            case state of
                Empty ->
                    Nothing

                _ ->
                    Visit.initSince instance_ now
                        |> visitResult


update : Instance.State -> Maybe Visit -> State -> ( State, Maybe Run )
update instance_ mvisit state =
    -- we just joined `instance`, and just left `visit.instance`.
    --
    -- instance may be Nothing (the game just reopened) - the visit is
    -- treated as if the player were online while the game was closed,
    -- and restarted instantly into no-instance.
    -- No-instance always transitions to town (the player starts there).
    case mvisit of
        Nothing ->
            -- no visit, no changes.
            ( state, Nothing )

        Just visit ->
            let
                initRun npcSays =
                    if Instance.isMap instance_.val && Visit.isTown visit then
                        -- when not running, entering a map from town starts a run.
                        -- TODO: Non-town -> Map could be a Zana mission - skip for now, takes more special-casing
                        Started instance_.joinedAt npcSays

                    else
                        -- ...and *only* entering a map. Ignore non-maps while not running.
                        Empty
            in
            case state of
                Empty ->
                    ( initRun [], Nothing )

                Started _ npcSays ->
                    -- first complete visit of the run!
                    if Visit.isMap visit then
                        case init npcSays visit of
                            Nothing ->
                                -- we entered a map, then went offline. Discard the run+visit.
                                ( initRun npcSays, Nothing )

                            Just run ->
                                -- normal visit, common case - really start the run.
                                ( Running run, Nothing )

                    else
                        -- Debug.todo <| "A run's first visit should be a Map-zone, but it wasn't: " ++ Debug.toString visit
                        ( initRun npcSays, Nothing )

                Running running ->
                    case push visit running of
                        Nothing ->
                            -- they went offline during a run. Start a new run.
                            if Visit.isTown visit then
                                -- they went offline in town - end the run, discarding the time in town.
                                ( initRun [], Just running )

                            else
                                -- they went offline in the map or a side area.
                                -- we can't know how much time they actually spent running before disappearing - discard the run.
                                -- TODO handle offline in no-zone - imagine crashing in a map, immediately restarting the game, then quitting for the day
                                ( initRun [], Nothing )

                        Just run ->
                            if (not <| Instance.isTown instance_.val) && instance_.val /= run.first.instance && Visit.isTown visit then
                                -- entering a new non-town zone, from town, finishes this run and might start a new one. This condition is complex:
                                -- * Reentering the same map does not! Ex: death, or portal-to-town to dump some gear.
                                -- * Map -> Map does not! Ex: a Zana mission. TODO Zanas ought to split off into their own run, though.
                                -- * Even Non-Map -> Map does not! That's a Zana daily, or leaving an abyssal-depth/trial/other side-area.
                                -- * Town -> Non-Map does, though. Ex: map -> town -> uberlab.
                                ( initRun [], Just run )

                            else if instance_.val == run.first.instance && Visit.isTown visit then
                                -- reentering the *same* map from town is a portal.
                                ( Running { run | portals = run.portals + 1 }, Nothing )

                            else
                                -- the common case - just add the visit to the run
                                ( Running run, Nothing )


type alias Summary =
    { durs : DurationSet
    , best : Maybe Millis
    , num : Int
    }


summarize : List Run -> Summary
summarize runs =
    { durs = meanDurationSet runs
    , best = bestDuration .mainMap runs
    , num = List.length runs
    }


stateLastUpdatedAt : State -> Maybe Time.Posix
stateLastUpdatedAt state =
    case state of
        Empty ->
            Nothing

        Started t _ ->
            Just t

        Running run ->
            Just run.last.leftAt


updateNPCText : LogLine.Line -> State -> State
updateNPCText line state =
    case line.info of
        LogLine.NPCSays says ->
            case state of
                Empty ->
                    state

                Started t npcSays ->
                    Started t (says :: npcSays)

                Running run ->
                    Running { run | npcSays = says :: run.npcSays }

        _ ->
            state
