module MapRun exposing (MapRun, fromEntries, fromCurrentEntries, totalDuration, averageDuration, durations, averageDurations)

import Date
import Time
import Dict
import Entry
import Zone


type alias MapRun =
    { started : Date.Date
    , startZone : Maybe String
    , durations : Dict.Dict String Time.Time
    , entries : List Entry.Entry -- for debugging
    , portals : Int
    }


splitDone : List Entry.Entry -> ( List Entry.Entry, List Entry.Entry )
splitDone newestEntries =
    let
        start : Maybe Entry.Instance
        start =
            -- the second-oldest entry - first-oldest is town
            newestEntries |> List.reverse |> List.head |> Maybe.andThen .instance

        next first rest =
            rest
                |> loop
                |> \( remaining, ready ) -> ( first :: remaining, ready )

        loop newestEntries =
            case newestEntries of
                [] ->
                    ( [], [] )

                a :: [] ->
                    ( [ a ], [] )

                a :: b :: rest ->
                    case ( Entry.zoneType a, Entry.zoneType b ) of
                        -- A new run starts when we leave town into a *different* zone than the start zone.
                        ( Zone.NotTown, Zone.Town ) ->
                            if start == a.instance then
                                -- not a different zone, keep looping
                                next a (b :: rest)
                            else
                                -- The last/newest entry is in both: start-time in one, finish-time in another.
                                ( [ a ], a :: b :: rest )

                        _ ->
                            next a (b :: rest)
    in
        loop newestEntries


fromPartialEntries : List Entry.Entry -> Maybe MapRun
fromPartialEntries newestEntries =
    let
        loop : List Entry.Entry -> MapRun -> MapRun
        loop oldestEntries run =
            case oldestEntries of
                [] ->
                    Debug.crash ("empty list in fromEntries.loop???" ++ toString newestEntries)

                a :: [] ->
                    run

                a :: b :: rest ->
                    let
                        zone =
                            case a.instance of
                                Just { zone } ->
                                    zone

                                Nothing ->
                                    "(none)"

                        dur =
                            Date.toTime b.at - Date.toTime a.at

                        updateDur cur =
                            case cur of
                                Nothing ->
                                    Just dur

                                Just cur ->
                                    Just <| dur + cur

                        dPortals =
                            -- town->town doesn't count as a portal
                            if (Entry.zoneType a == Zone.Town) && (Entry.zoneType b /= Zone.Town) then
                                1
                            else
                                0
                    in
                        loop (b :: rest)
                            { run
                                | durations = Dict.update zone updateDur run.durations

                                -- , entries = a :: run.entries
                                , portals = run.portals + dPortals
                            }

        oldestEntries =
            List.reverse newestEntries
    in
        case oldestEntries of
            [] ->
                Nothing

            oldest :: rest ->
                loop oldestEntries
                    { durations = Dict.empty
                    , entries = []
                    , started = oldest.at
                    , startZone = Maybe.map .zone oldest.instance
                    , portals = 0
                    }
                    |> Just


fromEntries : List Entry.Entry -> Maybe ( MapRun, List Entry.Entry )
fromEntries entries =
    let
        ( remainingEntries, readyEntries ) =
            splitDone entries
    in
        fromPartialEntries readyEntries
            |> Maybe.map (\run -> ( run, remainingEntries ))


fromCurrentEntries : Date.Date -> List Entry.Entry -> Maybe MapRun
fromCurrentEntries now entries =
    fromPartialEntries <| { instance = Nothing, at = now } :: entries


type alias DurationSet =
    { total : Time.Time, town : Time.Time, start : Time.Time, subs : Time.Time, notTown : Time.Time }


filteredDuration : (String -> Time.Time -> Bool) -> Dict.Dict String Time.Time -> Time.Time
filteredDuration pred dict =
    dict
        |> Dict.filter pred
        |> Dict.values
        |> List.sum


totalDuration : MapRun -> Time.Time
totalDuration run =
    filteredDuration (\_ -> always True) run.durations


durations : MapRun -> DurationSet
durations run =
    let
        total =
            totalDuration run

        town =
            filteredDuration (\z -> always <| Zone.isTown z) run.durations

        notTown =
            filteredDuration (\z -> always <| not <| Zone.isTown z) run.durations

        start =
            filteredDuration (\z -> always <| Just z == run.startZone) run.durations
    in
        { total = total, town = town, notTown = notTown, start = start, subs = notTown - start }


averageDuration : List MapRun -> Time.Time
averageDuration runs =
    List.sum (List.map totalDuration runs) / (toFloat <| List.length runs)


averageDurations : List MapRun -> DurationSet
averageDurations runs =
    let
        durs =
            List.map durations runs

        avg getter =
            (durs |> List.map getter |> List.sum) / (List.length runs |> toFloat)
    in
        { total = avg .total, town = avg .town, notTown = avg .notTown, start = avg .start, subs = avg .subs }
