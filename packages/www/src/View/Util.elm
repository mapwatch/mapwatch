module View.Util exposing (..)

import Html as H
import Html.Attributes as A
import Html.Events as E
import View.Icon as Icon
import Mapwatch exposing (Model, Msg)
import Regex


roundToPlaces : Float -> Float -> Float
roundToPlaces p n =
    (n * (10 ^ p) |> round |> toFloat) / (10 ^ p)


viewSearch : List (H.Attribute msg) -> (String -> msg) -> Maybe String -> H.Html msg
viewSearch attrs msg search =
    H.span [ A.class "search-text" ]
        [ H.input
            ([ A.value <| Maybe.withDefault "" search
             , A.type_ "text"
             , A.tabindex 1
             , E.onInput msg
             ]
                ++ attrs
            )
            []
        , Icon.fas "search"
        ]


viewGoalForm : (Maybe String -> msg) -> { a | goal : Maybe String, after : Maybe b, enableGoals : Bool } -> H.Html msg
viewGoalForm onChange0 qs =
    let
        sessionName =
            case qs.after of
                Just _ ->
                    "session"

                Nothing ->
                    "today's"

        ( optExactly, exactly ) =
            Maybe.withDefault ( [], [] ) <|
                Maybe.andThen
                    (\dur ->
                        if Regex.contains (Regex.regex "best|mean|none") dur then
                            Nothing
                        else
                            Just ( [ A.selected True ], [ H.input [ A.type_ "text", E.onInput onChange, A.value dur, A.placeholder "\"5:00\" or \"300\" or \"5m 0s\"" ] [] ] )
                    )
                    qs.goal

        onChange str =
            onChange0 <|
                if str == "none" then
                    Nothing
                else
                    Just str
    in
        if qs.enableGoals then
            H.span []
                [ H.select [ E.onInput onChange ]
                    [ H.option [ A.selected <| qs.goal == Nothing || qs.goal == Just "none", A.value "none" ] [ H.text "No time goal" ]
                    , H.option [ A.selected <| qs.goal == Just "best-session", A.value "best-session" ] [ H.text <| "Goal: " ++ sessionName ++ " best" ]
                    , H.option [ A.selected <| qs.goal == Just "best", A.value "best" ] [ H.text <| "Goal: all-time best" ]
                    , H.option [ A.selected <| qs.goal == Just "mean-session", A.value "mean-session" ] [ H.text <| "Goal: " ++ sessionName ++ " average" ]
                    , H.option [ A.selected <| qs.goal == Just "mean", A.value "mean" ] [ H.text <| "Goal: all-time average" ]
                    , H.option (optExactly ++ [ A.value "" ]) [ H.text "Goal: exactly..." ]
                    ]
                , H.span [] exactly
                ]
        else
            H.span [] []


pluralize : String -> String -> number -> String
pluralize one other n =
    if n == 1 then
        one
    else
        other
