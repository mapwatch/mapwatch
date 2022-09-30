module Page.SharedBosses exposing (view)

import Dict exposing (Dict)
import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Localization.Mapwatch as L
import Mapwatch
import Mapwatch.BossEntry as BossEntry exposing (BossEntry, Progress)
import Mapwatch.BossShare as BossShare
import Mapwatch.BossTally as BossTally exposing (BossTally)
import Mapwatch.Datamine as Datamine exposing (Datamine, WorldArea)
import Mapwatch.EncounterTally as EncounterTally exposing (EncounterTally)
import Mapwatch.Instance as Instance exposing (Instance)
import Mapwatch.MapRun as MapRun exposing (MapRun)
import Mapwatch.MapRun.Sort as RunSort
import Model as Model exposing (Msg(..), OkModel)
import Page.Bosses
import Route exposing (Route)
import Route.Feature as Feature exposing (Feature)
import Route.QueryDict as QueryDict exposing (QueryDict)
import Time exposing (Posix)
import View.Home
import View.Icon as Icon
import View.Nav
import View.Setup
import View.Util


view : String -> OkModel -> Html Msg
view code model =
    div [ class "main" ]
        [ View.Home.viewHeader model

        -- , View.Nav.view model
        , viewBody code
        ]


viewBody : String -> Html Msg
viewBody code =
    div []
        [ text code
        , div [] [ text <| String.fromInt <| String.length code ]
        , case BossShare.base64Decode code of
            Err err ->
                pre [] [ text err ]

            Ok share ->
                share.tally |> Page.Bosses.viewBossTally Dict.empty |> div []
        ]
