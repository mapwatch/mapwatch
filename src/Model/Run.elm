module Model.Run
    exposing
        ( Run
        , State(..)
        , DurationSet
        , init
        , duration
        , durationSet
        , totalDurationSet
        , meanDurationSet
        , stateDuration
        , durationPerSideArea
        , bestDuration
        , search
        , groupMapNames
        , filterToday
        , current
        , update
        , tick
        )

import Time
import Date
import Dict
import Regex
import Dict.Extra
import Maybe.Extra
import Model.Instance as Instance exposing (Instance)
import Model.Visit as Visit exposing (Visit)


type alias Run =
    { visits : List Visit, first : Visit, last : Visit, portals : Int }


type State
    = Empty
    | Started Date.Date
    | Running Run


init : Visit -> Maybe Run
init visit =
    if Visit.isOffline visit || not (Visit.isMap visit) then
        Nothing
    else
        Just { first = visit, last = visit, visits = [ visit ], portals = 1 }


instance : Run -> Instance
instance run =
    -- this is guaranteed because init checks for it
    case run.first.instance of
        Nothing ->
            Debug.crash "null-instance run"

        Just i ->
            i


search : String -> List Run -> List Run
search query =
    let
        pred run =
            Regex.contains (Regex.regex query |> Regex.caseInsensitive) (instance run).zone
    in
        List.filter pred


stateDuration : Date.Date -> State -> Maybe Time.Time
stateDuration now state =
    case state of
        Empty ->
            Nothing

        Started at ->
            Just <| max 0 <| Date.toTime now - Date.toTime at

        Running run ->
            Just <| max 0 <| Date.toTime now - Date.toTime run.first.joinedAt


duration : Run -> Time.Time
duration v =
    max 0 <| Date.toTime v.last.leftAt - Date.toTime v.first.joinedAt


filteredDuration : (Visit -> Bool) -> Run -> Time.Time
filteredDuration pred run =
    run.visits
        |> List.filter pred
        |> List.map Visit.duration
        |> List.sum


type alias DurationSet =
    { all : Time.Time, town : Time.Time, start : Time.Time, subs : Time.Time, notTown : Time.Time, portals : Float }


durationSet : Run -> DurationSet
durationSet run =
    let
        all =
            duration run

        town =
            filteredDuration Visit.isTown run

        notTown =
            filteredDuration (not << Visit.isTown) run

        start =
            filteredDuration (\v -> v.instance == run.first.instance) run
    in
        { all = all, town = town, notTown = notTown, start = start, subs = notTown - start, portals = toFloat run.portals }


totalDurationSet : List Run -> DurationSet
totalDurationSet runs =
    let
        durs =
            List.map durationSet runs

        sum get =
            durs |> List.map get |> List.sum
    in
        { all = sum .all, town = sum .town, notTown = sum .notTown, start = sum .start, subs = sum .subs, portals = sum .portals }


meanDurationSet : List Run -> DurationSet
meanDurationSet runs =
    let
        d =
            totalDurationSet runs

        n =
            List.length runs
                -- nonzero, since we're dividing. Numerator will be zero, so result is zero, that's fine.
                |> max 1
                |> toFloat
    in
        { all = d.all / n, town = d.town / n, notTown = d.notTown / n, start = d.start / n, subs = d.subs / n, portals = d.portals / n }


bestDuration : List Run -> Maybe Time.Time
bestDuration runs =
    runs
        |> List.map (durationSet >> .start)
        |> List.minimum


filterToday : Date.Date -> List Run -> List Run
filterToday date =
    let
        ymd date =
            ( Date.year date, Date.month date, Date.day date )

        pred run =
            ymd date == ymd run.last.leftAt
    in
        List.filter pred


byMap : List Run -> Dict.Dict String (List Run)
byMap =
    Dict.Extra.groupBy (instance >> .zone)


groupMapNames : List Run -> List { a | name : String } -> List ( { a | name : String }, List Run )
groupMapNames runs maps =
    let
        dict =
            byMap runs
    in
        maps
            |> List.map (\map -> Dict.get map.name dict |> Maybe.map ((,) map))
            |> Maybe.Extra.values


durationPerSideArea : Run -> List ( Instance, Time.Time )
durationPerSideArea run =
    durationPerInstance run
        |> List.filter (\( i, _ ) -> (not <| Instance.isTown i) && (i /= run.first.instance))
        |> List.map
            (\( i, d ) ->
                case i of
                    Just i ->
                        ( i, d )

                    Nothing ->
                        Debug.crash "Instance.isTown should have filtered this one"
            )


durationPerInstance : Run -> List ( Maybe Instance, Time.Time )
durationPerInstance { visits } =
    let
        instanceToZoneKey instance =
            case instance of
                Just i ->
                    i.zone

                Nothing ->
                    "(none)"

        zoneKeyToZone key =
            -- really wish dictionaries had more flexible keys
            if key == "(none)" then
                Nothing
            else
                Just key

        update instance duration val0 =
            val0
                |> Maybe.withDefault ( instance, 0 )
                |> Tuple.mapSecond ((+) duration)
                |> Just

        foldDurs ( instance, duration ) dict =
            Dict.update (instanceToZoneKey instance) (update instance duration) dict
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


tick : Date.Date -> Instance.State -> State -> ( State, Maybe Run )
tick now instance state =
    -- go offline when time has passed since the last log entry.
    case state of
        Empty ->
            ( state, Nothing )

        Started at ->
            if Instance.isOffline now instance then
                -- we just went offline while in a map - end/discard the run
                ( Empty, Nothing )
                    |> Debug.log "Run.tick: Started -> offline"
            else
                -- no changes
                ( state, Nothing )

        Running run ->
            if Instance.isOffline now instance then
                -- they went offline during a run. Start a new run.
                if Instance.isTown instance.val then
                    -- they went offline in town - end the run, discarding the time in town.
                    ( Empty, Just run )
                        |> Debug.log "Run.tick: Running<town> -> offline"
                else
                    -- they went offline in the map or a side area.
                    -- we can't know how much time they actually spent running before disappearing - discard the run.
                    ( Empty, Nothing )
                        |> Debug.log "Run.tick: Running<not-town> -> offline"
            else
                -- no changes
                ( state, Nothing )


current : Date.Date -> Instance.State -> State -> Maybe Run
current now instance state =
    let
        visitResult v =
            case update instance (Just v) state of
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
                Visit.initSince instance now
                    |> visitResult


update : Instance.State -> Maybe Visit -> State -> ( State, Maybe Run )
update instance visit state =
    -- we just joined `instance`, and just left `visit.instance`.
    --
    -- instance may be Nothing (the game just reopened) - the visit is
    -- treated as if the player were online while the game was closed,
    -- and restarted instantly into no-instance.
    -- No-instance always transitions to town (the player starts there).
    case visit of
        Nothing ->
            -- no visit, no changes.
            ( state, Nothing )

        Just visit ->
            let
                initRun =
                    if Instance.isMap instance.val && Visit.isTown visit then
                        -- when not running, entering a map from town starts a run.
                        -- TODO: Non-town -> Map could be a Zana mission - skip for now, takes more special-casing
                        case instance.joinedAt of
                            Just at ->
                                Started at

                            Nothing ->
                                -- TODO change the Instance.State type to prevent this
                                Debug.crash <| "instance.state has {val=notnull, joinedAt=null}: " ++ toString instance
                    else
                        -- ...and *only* entering a map. Ignore non-maps while not running.
                        Empty
            in
                case state of
                    Empty ->
                        ( initRun, Nothing )

                    Started _ ->
                        -- first complete visit of the run!
                        if Visit.isMap visit then
                            case init visit of
                                Nothing ->
                                    -- we entered a map, then went offline. Discard the run+visit.
                                    ( initRun, Nothing )

                                Just run ->
                                    -- normal visit, common case - really start the run.
                                    ( Running run, Nothing )
                        else
                            Debug.crash <| "A run's first visit should be a Map-zone, but it wasn't: " ++ toString visit

                    Running run ->
                        case push visit run of
                            Nothing ->
                                -- they went offline during a run. Start a new run.
                                if Visit.isTown visit then
                                    -- they went offline in town - end the run, discarding the time in town.
                                    ( initRun, Just run )
                                else
                                    -- they went offline in the map or a side area.
                                    -- we can't know how much time they actually spent running before disappearing - discard the run.
                                    -- TODO handle offline in no-zone - imagine crashing in a map, immediately restarting the game, then quitting for the day
                                    ( initRun, Nothing )

                            Just run ->
                                if (not <| Instance.isTown instance.val) && instance.val /= run.first.instance && Visit.isTown visit then
                                    -- entering a new non-town zone, from town, finishes this run and might start a new one. This condition is complex:
                                    -- * Reentering the same map does not! Ex: death, or portal-to-town to dump some gear.
                                    -- * Map -> Map does not! Ex: a Zana mission. TODO Zanas ought to split off into their own run, though.
                                    -- * Even Non-Map -> Map does not! That's a Zana daily, or leaving an abyssal-depth/trial/other side-area.
                                    -- * Town -> Non-Map does, though. Ex: map -> town -> uberlab.
                                    ( initRun, Just run )
                                else if instance.val == run.first.instance && Visit.isTown visit then
                                    -- reentering the *same* map from town is a portal.
                                    ( Running { run | portals = run.portals + 1 }, Nothing )
                                else
                                    -- the common case - just add the visit to the run
                                    ( Running run, Nothing )
