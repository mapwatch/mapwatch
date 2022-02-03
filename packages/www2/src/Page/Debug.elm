module Page.Debug exposing (view)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Json.Encode as E
import Model exposing (Msg, OkModel)
import Route exposing (Route)
import Route.Feature as Feature exposing (Feature)
import View.Home
import View.Nav
import View.Setup


view : OkModel -> Html Msg
view model =
    div [ class "main" ]
        [ View.Home.viewHeader model
        , View.Nav.view model
        , h5 [] [ text "secret debugging tools" ]
        , p [] [ text "Platform: ", code [] [ text model.flags.platform ] ]
        , p [] [ text "Version: ", code [] [ text model.flags.version ] ]
        , b [] [ text "Features:" ]
        , ul []
            (Feature.list
                |> List.map
                    (\f ->
                        li []
                            [ a [ Route.href (Feature.toggle f model.query) Route.Debug ]
                                [ text <| Feature.string f ++ "=" ++ Feature.boolToString (Feature.isActive f model.query) ]
                            ]
                    )
            )
        , div []
            [ button [ onClick <| Model.DebugNotification debugNotification ] [ text "Send test notification" ]
            , div [] [ small [] [ text "The downloadable app uses these notifications when a version update is auto-installed." ] ]
            , div [] [ small [] [ text "This test button won't work on the website: no notification permissions (we don't use them anywhere else)" ] ]
            ]
        , b [] [ text "Pages:" ]
        , ul []
            [ li [] [ a [ Route.href model.query Route.DebugDatamine ] [ text "/debug/datamine" ] ]
            , li [] [ a [ Route.href model.query Route.DebugDumpLines ] [ text "/debug/dumplines (broken)" ] ]
            ]
        , b [] [ text "Test cases:" ]
        , ul []
            (testCases
                |> List.map
                    (\( file, query, comment ) ->
                        li []
                            [ a [ target "_blank", href <| "?example=" ++ file ++ query ] [ text file ]
                            , text " ("
                            , a [ target "_blank", href <| "/examples/" ++ file ] [ text "raw" ]
                            , text "): "
                            , text comment
                            ]
                    )
            )
        ]


testCases : List ( String, String, String )
testCases =
    [ ( View.Setup.example.file, View.Setup.example.query, "Front page's \"Run an example now!\"" )
    , ( "laboratory.txt", "#/history", "Laboratory map vs. heist" )
    , ( "grand-heist.txt", "#/history", "Heist-contract vs. Grand-heist" )
    , ( "shaper-uberelder.txt", "#/history", "Shaper vs Uber-Elder in \"The Shaper's Realm\"" )
    , ( "oshabi-boss.txt", "#/history", "Oshabi boss-fight vs. standard harvest" )
    , ( "chinese-client.txt", "&tickStart=1526227994000&logtz=0#/history", "Chinese client test. BROKEN since ggpk reformat: https://github.com/mapwatch/mapwatch/issues/118" )
    , ( "simulacrum.txt", "&tickStart=1526927461000&logtz=0#/history", "Simulacrum has a 60min timeout, other maps have 30min" )
    , ( "daylight-savings.txt", "&tickStart=1603996952265&logtz=0#/history", "DST" )
    , ( "short-client.txt", "#/history", "for testing text-to-speech" )
    , ( "235.txt", "#/history", "test case from https://github.com/mapwatch/mapwatch/issues/235" )
    , ( "ritual.txt", "#/history", "test case for ritual reminder" )
    ]


debugNotification : E.Value
debugNotification =
    E.list identity
        [ E.string "mapwatch debug notification"
        , E.object
            [ ( "body", E.string "hello from the mapwatch debug screen" )
            ]
        ]
