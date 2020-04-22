module View.DebugTranslator exposing (view)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Localized
import Maybe.Extra
import Model exposing (Msg, OkModel)
import Route as Route exposing (Route)
import View.Home
import View.Icon
import View.Nav


view : OkModel -> Html Msg
view model =
    div [ class "main" ]
        [ View.Home.viewHeader model
        , View.Nav.view model
        , h3 []
            [ a [ target "_blank", href "https://github.com/mapwatch/mapwatch/blob/master/TRANSLATING.md" ]
                [ text "Debug: Live Translations" ]
            ]
        , p []
            [ a [ target "_blank", href "https://github.com/mapwatch/mapwatch/blob/master/TRANSLATING.md" ]
                [ text "Thank you for your help translating Mapwatch!" ]
            ]
        , p []
            [ text "Input some "
            , a [ target "_blank", href "https://www.projectfluent.org" ] [ text "Fluent" ]
            , text " code below. "
            , text "You could start with the "
            , a [ target "_blank", href "https://github.com/mapwatch/mapwatch/tree/master/packages/www/src/lang/en-us.ftl.properties" ] [ text "original English translation file" ]
            , text ", "
            , a [ target "_blank", href "https://github.com/mapwatch/mapwatch/tree/master/packages/www/src/lang/" ] [ text "any other Mapwatch translation file" ]
            , text ", or simply try typing "
            , code [] [ text "title = hello hello!" ]
            , text "."
            ]
        , textarea [ rows 40, cols 80, onInput Model.InputLiveTranslation ]
            [ text <| Maybe.withDefault "" model.settings.liveTranslation ]
        ]
