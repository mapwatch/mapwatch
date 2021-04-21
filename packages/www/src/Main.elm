module Main exposing (main)

import AppPlatform
import Browser
import Html as H exposing (..)
import Mapwatch
import Model exposing (Model, Msg)
import Page.Changelog
import Page.Debug
import Page.DebugDatamine
import Page.DumpLines
import Page.Encounters
import Page.GSheets
import Page.History
import Page.HistoryTSV
import Page.LogSlice
import Page.Maps
import Page.NotFound
import Page.Overlay
import Page.Privacy
import Page.Settings
import Page.Timer
import Route exposing (Route(..))


main =
    Browser.application
        { init = Model.init
        , update = Model.update
        , subscriptions = Model.subscriptions
        , view = view
        , onUrlRequest = Model.NavRequest
        , onUrlChange = Model.NavLocation
        }


view : Model -> Browser.Document Msg
view model =
    { title = "PoE Mapwatch", body = [ viewBody model ] }


viewBody : Model -> Html Msg
viewBody rmodel =
    case rmodel of
        Err err ->
            pre [] [ text err ]

        Ok model ->
            case model.route of
                History ->
                    Page.History.view model

                HistoryTSV ->
                    Page.HistoryTSV.view model

                GSheets ->
                    Page.GSheets.view model

                Maps ->
                    Page.Maps.view model

                Encounters ->
                    Page.Encounters.view model

                Timer ->
                    Page.Timer.view model

                Overlay ->
                    Page.Overlay.view model

                Debug ->
                    Page.Debug.view model

                DebugDumpLines ->
                    Page.DumpLines.view model

                DebugDatamine ->
                    Page.DebugDatamine.view model.query model.mapwatch.datamine

                Changelog ->
                    Page.Changelog.view model

                Privacy ->
                    Page.Privacy.view model

                Settings ->
                    Page.Settings.view model

                LogSlice posStart posEnd ->
                    Page.LogSlice.view posStart posEnd model

                NotFound loc ->
                    Page.NotFound.view model
