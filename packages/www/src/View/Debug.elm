module View.Debug exposing (view)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Model exposing (OkModel)
import Route exposing (Route)
import Route.Feature as Feature exposing (Feature)
import View.Home exposing (viewHeader)
import View.Nav


view : OkModel -> Html msg
view model =
    div [ class "main" ]
        [ viewHeader
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
        , b [] [ text "Pages:" ]
        , ul []
            [ li [] [ a [ Route.href model.query Route.DebugDatamine ] [ text "/debug/datamine" ] ]
            , li [] [ a [ Route.href model.query Route.DebugDumpLines ] [ text "/debug/dumplines (broken)" ] ]
            ]
        ]
