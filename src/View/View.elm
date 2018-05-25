module View.View exposing (view)

import Html as H
import Model as Model exposing (Model, Msg)
import Model.Route as Route exposing (Route(..))
import View.History
import View.Timer
import View.DumpLines
import View.MapIcons
import View.NotFound
import View.Maps
import View.Changelog


view : Model -> H.Html Msg
view model =
    case model.route of
        HistoryRoot ->
            View.History.view (Route.HistoryParams 0 Nothing Nothing Nothing Nothing) model

        History params ->
            View.History.view params model

        MapsRoot ->
            View.Maps.view (Route.MapsParams Nothing Nothing Nothing) model

        Maps params ->
            View.Maps.view params model

        Timer qs ->
            View.Timer.view qs model

        Debug ->
            H.div [] [ H.text "TODO" ]

        DebugDumpLines ->
            View.DumpLines.view model

        DebugMapIcons ->
            View.MapIcons.view

        Changelog ->
            View.Changelog.view model.route

        NotFound loc ->
            View.NotFound.view
