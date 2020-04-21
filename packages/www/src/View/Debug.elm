module View.Debug exposing (view)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Json.Encode as E
import Model exposing (Msg, OkModel)
import Route exposing (Route)
import Route.Feature as Feature exposing (Feature)
import View.Home
import View.Nav


view : OkModel -> Html Msg
view model =
    -- debug tools are deliberately not translated, I only support them for myself
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
        ]


debugNotification : E.Value
debugNotification =
    E.list identity
        [ E.string "mapwatch debug notification"
        , E.object
            [ ( "body", E.string "hello from the mapwatch debug screen" )
            ]
        ]
