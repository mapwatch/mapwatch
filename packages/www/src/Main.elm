module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes as A
import Model exposing (Model, Msg)
import Page.Bosses
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
import Page.SharedBosses
import Page.Timer
import Route exposing (Route(..))
import Route.Feature as Feature


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
    { title = "", body = [ viewBody model ] }


viewBody : Model -> Html Msg
viewBody rmodel =
    if True then
        div []
            [ h1 [] [ text "Mapwatch is no longer maintained." ]
            , p [] [ text "Mapwatch used to show statistics about your recent Path of Exile mapping activity, based on your ", code [] [ text "client.txt" ], text " file. As of June 2024, it's discontinued." ]
            , p [] [ text "Thanks for your love over the years!" ]
            , h3 [] [ text "What can you use instead?" ]
            , p []
                [ b [] [ text "For a current-map stopwatch" ]
                , text ", the "
                , a [ A.target "_blank", A.href "https://www.pathofexile.com/shop/item/TimekeepersMapDeviceVariations" ] [ text "Timekeeper's Map Device" ]
                , text " is available in the shop now. It's better than Mapwatch ever was - well worth the cost!"
                ]
            , p []
                [ b [] [ text "For a history of your maps this league" ]
                , text ", I've heard good things about "
                , a [ A.target "_blank", A.href "https://github.com/dermow/TraXile" ] [ text "TraXile" ]
                , text ". Other options include "
                , a [ A.target "_blank", A.href "https://github.com/exilence-ce/exilence-ce" ] [ text "Exilence CE" ]
                , text " and "
                , a [ A.target "_blank", A.href "https://poestack-next.vercel.app/" ] [ text "Poestack" ]
                , text ". I haven't personally used any of these, so good luck!"
                ]
            , h3 [] [ text "I found another tool named \"Mapwatch\". Is it related to the original Mapwatch?" ]
            , p [] [ text "No, \"mypoe.site[/]mapwatch\" is not related to this tool, the original Mapwatch. It uses the same name, and it does something similar, but it is not the same tool. It was created much later than this one. I am not its developer." ]
            ]

    else
        case rmodel of
            Err err ->
                pre [] [ text err ]

            Ok model ->
                let
                    v =
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

                            Bosses ->
                                Page.Bosses.view model

                            SharedBosses code ->
                                Page.SharedBosses.view code model

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
                in
                div
                    (if Feature.isActive Feature.DebugLocalization model.query then
                        [ A.class "debug-localization" ]

                     else
                        []
                    )
                    [ v ]
