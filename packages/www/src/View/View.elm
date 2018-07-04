module View.View exposing (view)

import Html as H
import Model as Model exposing (Model, Msg)
import Mapwatch as Mapwatch
import Route exposing (Route(..))
import View.History
import View.Timer
import View.Overlay
import View.DumpLines
import View.MapIcons
import View.NotFound
import View.Maps
import View.Changelog


view : Model -> H.Html Msg
view model =
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
            H.div [] [ H.text "TODO" ]

        DebugDumpLines ->
            View.DumpLines.view model

        DebugMapIcons ->
            View.MapIcons.view

        Changelog ->
            View.Changelog.view model.changelog

        NotFound loc ->
            View.NotFound.view
