module View.Debug exposing (view)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Model exposing (OkModel)
import Route exposing (Route)
import View.Home exposing (viewHeader)
import View.Nav


view : OkModel -> Html msg
view model =
    div [ class "main" ]
        [ viewHeader
        , View.Nav.view Nothing
        , h5 [] [ text "secret debugging tools" ]
        , ul []
            [ li [] [ a [ Route.href Route.DebugDatamine ] [ text "/debug/datamine" ] ]
            , li [] [ a [ Route.href Route.DebugDumpLines ] [ text "/debug/dumplines (broken)" ] ]
            ]
        , p [] [ text "Platform: ", code [] [ text model.flags.platform ] ]
        , p [] [ text "Version: ", code [] [ text model.flags.version ] ]
        ]
