module View.View exposing (view, viewBody)

import AppPlatform
import Browser
import Html as H
import Mapwatch as Mapwatch
import Model as Model exposing (Model, Msg)
import Route exposing (Route(..))
import View.Changelog
import View.DumpLines
import View.History
import View.MapIcons
import View.Maps
import View.NotFound
import View.Overlay
import View.Timer


view : Model -> Browser.Document Msg
view model =
    { title = "PoE Mapwatch", body = [ viewBody model ] }


viewBody : Model -> H.Html Msg
viewBody model =
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
            View.Changelog.view (AppPlatform.hrefHostname model) model.changelog

        NotFound loc ->
            View.NotFound.view
