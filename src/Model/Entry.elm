module Model.Entry exposing (Entry, Instance, fromLogLines, zoneType)

import Date
import Model.LogLine as LogLine
import Model.Zone as Zone


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


zoneType : Entry -> Zone.Type
zoneType entry =
    entry.instance
        |> Maybe.map .zone
        |> Zone.zoneType
