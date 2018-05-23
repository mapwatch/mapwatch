module View.View exposing (view)

import Html as H
import Model as Model exposing (Model, Msg)
import Model.Route as Route exposing (Route(..))
import View.Home
import View.History
import View.Timer
import View.DumpLines
import View.MapIcons
import View.NotFound
import View.Maps


view : Model -> H.Html Msg
view model =
    case model.route of
        Home ->
            View.Home.view model

        HistoryRoot ->
            View.History.view { page = 0, search = "" } model

        History params ->
            View.History.view params model

        MapsRoot ->
            View.Maps.view "" model

        Maps search ->
            View.Maps.view search model

        Timer ->
            View.Timer.view model

        Debug ->
            H.div [] [ H.text "TODO" ]

        DebugDumpLines ->
            View.DumpLines.view model

        DebugMapIcons ->
            View.MapIcons.view

        NotFound loc ->
            View.NotFound.view
