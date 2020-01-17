module View.View exposing (view, viewBody)

import AppPlatform
import Browser
import Html as H exposing (..)
import Mapwatch as Mapwatch
import Model as Model exposing (Model, Msg)
import Route exposing (Route(..))
import View.Changelog
import View.Debug
import View.DebugDatamine
import View.DumpLines
import View.History
import View.Maps
import View.NotFound
import View.Overlay
import View.Settings
import View.Timer


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
                History params ->
                    View.History.view params model

                Maps params ->
                    View.Maps.view params model

                Timer qs ->
                    View.Timer.view qs model

                Overlay qs ->
                    View.Overlay.view qs model

                Debug ->
                    View.Debug.view model

                DebugDumpLines ->
                    View.DumpLines.view model

                DebugDatamine ->
                    View.DebugDatamine.view model.mapwatch.datamine

                Changelog ->
                    View.Changelog.view model.flags.changelog

                Settings ->
                    View.Settings.view model

                NotFound loc ->
                    View.NotFound.view
