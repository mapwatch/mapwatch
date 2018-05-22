module View.View exposing (view)

import Html as H
import Model as Model exposing (Model, Msg)
import Model.Route as Route exposing (Route(..))
import View.Home
import View.History
import View.Timer
import View.DumpLines
import View.NotFound


view : Model -> H.Html Msg
view model =
    case model.route of
        Home ->
            View.Home.view model

        HistoryRoot ->
            View.History.view 0 model

        History page ->
            View.History.view page model

        Timer ->
            View.Timer.view model

        Debug ->
            H.div [] [ H.text "TODO" ]

        DebugDumpLines ->
            View.DumpLines.view model

        NotFound loc ->
            View.NotFound.view
