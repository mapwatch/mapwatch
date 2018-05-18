module Entry exposing (Entry, Instance, ZoneType(..), fromLogLines, zoneType)

import Date
import Set
import LogLine


type alias Instance =
    { zone : String, addr : String }


type alias Entry =
    { instance : Maybe Instance, at : Date.Date }


fromLogLines : List LogLine.Line -> Maybe Entry
fromLogLines lines =
    case lines of
        [] ->
            Nothing

        first :: _ ->
            case lines |> List.take 2 |> List.map .info of
                (LogLine.YouHaveEntered zone) :: (LogLine.ConnectingToInstanceServer addr) :: _ ->
                    Just { instance = Just { zone = zone, addr = addr }, at = first.date }

                LogLine.Opening :: _ ->
                    Just { instance = Nothing, at = first.date }

                _ ->
                    Nothing


towns : Set.Set String
towns =
    Set.fromList
        -- TODO
        [ "Oriath", "Enlightened Hideout" ]


type ZoneType
    = Town
    | NotTown
    | NotZone


zoneType_ : Maybe String -> ZoneType
zoneType_ zone =
    case zone of
        Nothing ->
            NotZone

        Just zone ->
            if Set.member zone towns then
                Town
            else
                NotTown


zoneType : Entry -> ZoneType
zoneType entry =
    entry.instance
        |> Maybe.map .zone
        |> zoneType_
