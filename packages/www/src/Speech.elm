module Speech exposing (Speech, encoder, joinInstance, progressComplete)

import Json.Encode as E
import Mapwatch.Instance as Instance exposing (Instance)
import Mapwatch.RawMapRun as RawMapRun exposing (RawMapRun)
import Mapwatch.MapRun as MapRun exposing (MapRun)
import Maybe.Extra
import Settings exposing (Settings)
import Time


type alias Speech =
    { volume : Float, text : String }


createSpeech : Settings -> String -> Speech
createSpeech s =
    Speech (toFloat s.volume / 100)


time =
    { second = 1000, minute = 1000 * 60, hour = 1000 * 60 * 60 }


mapRun : MapRun -> String
mapRun r =
    let
        m =
            r.duration.all // time.minute |> abs

        s =
            remainderBy time.minute r.duration.all // time.second |> abs
    in
    "finished in " ++ String.fromInt m ++ " minutes " ++ String.fromInt s ++ " seconds for " ++ r.address.zone ++ ". "


progressComplete : Settings -> String -> Maybe Speech
progressComplete settings name =
    if name == "history" || name == "history:example" then
        "mapwatch now running" |> createSpeech settings |> Just

    else
        Nothing


joinInstance : Settings -> Bool -> RawMapRun.State -> Maybe MapRun -> Instance -> Maybe Speech
joinInstance settings isHistoryDone runState lastRun instance =
    if isHistoryDone then
        let
            zone : String
            zone =
                instance |> Instance.zoneName |> Maybe.withDefault "unknown"

            text : Maybe String
            text =
                case ( lastRun |> Maybe.map mapRun, runState ) of
                    ( Nothing, Just _ ) ->
                        -- non-map -> map, or first run of the day
                        "mapwatch now starting " ++ zone ++ ". " |> Just

                    ( Nothing, _ ) ->
                        -- non-map -> non-map, or a run is still happening, or we're in a non-map zone
                        Nothing

                    ( Just finish, Nothing ) ->
                        -- map -> non-map
                        "mapwatch " ++ finish ++ " timer stopped. " |> Just

                    ( Just finish, _ ) ->
                        -- map -> (different) map
                        "mapwatch " ++ finish ++ " now starting " ++ zone ++ ". " |> Just
        in
        text |> Maybe.map (createSpeech settings)

    else
        Nothing


encoder : Speech -> E.Value
encoder s =
    E.object
        [ ( "text", s.text |> E.string )
        , ( "volume", s.volume |> E.float )
        ]
