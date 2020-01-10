module View.Debug exposing (view)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Model exposing (OkModel)
import Route exposing (Route)


view : OkModel -> Html msg
view model =
    div []
        [ ul []
            [ li [] [ a [ Route.href (Route.Timer Route.timerParams0) ] [ text "home" ] ]
            , li [] [ a [ Route.href Route.DebugDatamine ] [ text "/debug/datamine" ] ]
            , li [] [ a [ Route.href Route.DebugDumpLines ] [ text "/debug/dumplines" ] ]
            ]
        , p [] [ text "Platform: ", code [] [ text model.flags.platform ] ]
        ]
