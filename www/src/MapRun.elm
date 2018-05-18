module MapRun exposing (MapRun, fromEntries, fromCurrentEntries, totalDuration)

import Date
import Time
import Dict
import Entry


type alias MapRun =
    { started : Date.Date
    , startZone : Maybe String
    , durations : Dict.Dict String Time.Time
    , entries : List Entry.Entry
    }


splitDone : List Entry.Entry -> ( List Entry.Entry, List Entry.Entry )
splitDone newestEntries =
    case newestEntries of
        [] ->
            ( [], [] )

        a :: [] ->
            ( [ a ], [] )

        a :: b :: rest ->
            case ( Entry.zoneType a, Entry.zoneType b ) of
                -- A new run starts when we leave town. The last/newest entry is in both: start-time in one, finish-time in another.
                ( Entry.NotTown, Entry.Town ) ->
                    ( [ a ], a :: b :: rest )

                _ ->
                    let
                        ( remaining, ready ) =
                            splitDone <| b :: rest
                    in
                        ( a :: remaining, ready )


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
                    in
                        loop (b :: rest)
                            { run
                                | durations = Dict.update zone updateDur run.durations

                                -- , entries = a :: run.entries
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


totalDuration : MapRun -> Time.Time
totalDuration run =
    Dict.values run.durations |> List.sum
