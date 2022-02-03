module Pages.Debug exposing (page)

import Gen.Params.Debug exposing (Params)
import Gen.Route as Route exposing (Route)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Encode as E
import Model exposing (Msg, OkModel)
import Page exposing (Page)
import Request
import Route.Feature as Feature exposing (Feature)
import Route.QueryDict as QueryDict
import Shared
import Url.Builder
import View exposing (View)
import View.Home
import View.Nav
import View.Setup


type alias Request =
    Request.With Params


page : Shared.Model -> Request -> Page
page shared req =
    Page.static
        { view = view shared req
        }


view : Shared.Model -> Request -> View msg
view model req =
    { title = "", body = viewBody model req }


viewBody : Shared.Model -> Request -> List (Html msg)
viewBody model req =
    [ div [ class "main" ]
        -- [ View.Home.viewHeader model
        -- , View.Nav.view model
        [ h5 [] [ text "secret debugging tools" ]
        , p [] [ text "Platform: ", code [] [ text model.flags.platform ] ]
        , p [] [ text "Version: ", code [] [ text model.flags.version ] ]
        , b [] [ text "Features:" ]
        , ul []
            (Feature.list
                |> List.map
                    (\f ->
                        li []
                            [ a [ href <| Route.toHref Route.Debug ++ (req.query |> Feature.toggle f |> QueryDict.toString { prefix = True, filter = Nothing }) ]
                                [ text <| Feature.string f ++ "=" ++ Feature.boolToString (Feature.isActive f req.query) ]
                            ]
                    )
            )
        , div []
            -- [ button [ onClick <| Model.DebugNotification debugNotification ] [ text "Send test notification" ]
            [ button [] [ text "Send test notification (BROKEN)" ]
            , div [] [ small [] [ text "The downloadable app uses these notifications when a version update is auto-installed." ] ]
            , div [] [ small [] [ text "This test button won't work on the website: no notification permissions (we don't use them anywhere else)" ] ]
            ]
        , b [] [ text "Pages:" ]
        , ul []
            [ li [] [ a [ href <| Route.toHref Route.Debug__Datamine ] [ text "/debug/datamine" ] ]

            -- [ li [] [ a [ href <| Route.toHref <| model.query Route.DebugDatamine ] [ text "/debug/datamine" ] ]
            -- , li [] [ a [ href <| Route.toHref <| model.query Route.DebugDumpLines ] [ text "/debug/dumplines (broken)" ] ]
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
