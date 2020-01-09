module Speech exposing (joinInstance, mapRun)

import Mapwatch.Instance as Instance exposing (Instance)
import Mapwatch.Run as Run exposing (Run)
import Maybe.Extra
import Time


time =
    { second = 1000, minute = 1000 * 60, hour = 1000 * 60 * 60 }


mapRun : Run -> String
mapRun r =
    let
        dur =
            Run.duration r

        m =
            dur // time.minute |> abs

        s =
            remainderBy time.minute dur // time.second |> abs
    in
    "finished in " ++ String.fromInt m ++ " minutes " ++ String.fromInt s ++ " seconds for " ++ (Run.instance r).zone ++ ". "


joinInstance : Run.State -> Maybe Run -> Instance -> Maybe String
joinInstance runState lastRun instance =
    let
        zone : String
        zone =
            instance |> Instance.zoneName |> Maybe.withDefault "unknown"
    in
    -- case ( lastRun |> Maybe.map mapRun, instance |> Instance.isMap ) of
    case ( lastRun |> Maybe.map mapRun, runState ) of
        ( Nothing, Run.Started _ ) ->
            -- non-map -> map, or first run of the day
            "mapwatch now starting " ++ zone ++ ". " |> Just

        ( Nothing, _ ) ->
            -- non-map -> non-map, or a run is still happening, or we're in a non-map zone
            Nothing

        ( Just finish, Run.Empty ) ->
            -- map -> non-map
            "mapwatch " ++ finish ++ " timer stopped. " |> Just

        ( Just finish, _ ) ->
            -- map -> (different) map
            "mapwatch " ++ finish ++ " now starting " ++ zone ++ ". " |> Just
