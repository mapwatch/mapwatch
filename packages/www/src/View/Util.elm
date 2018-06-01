module View.Util exposing (..)

import Html as H
import Html.Attributes as A
import Html.Events as E
import View.Icon as Icon
import Regex
import Time as Time exposing (Time)
import Date as Date exposing (Date)
import Mapwatch exposing (Model, Msg)
import Route as Route exposing (Route)


roundToPlaces : Float -> Float -> Float
roundToPlaces p n =
    (n * (10 ^ p) |> round |> toFloat) / (10 ^ p)


viewSearch : List (H.Attribute msg) -> (String -> msg) -> Maybe String -> H.Html msg
viewSearch attrs msg search =
    H.span [ A.class "search-form search-text" ]
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
            H.span [ A.class "search-form search-goal" ]
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


leagueName =
    "Incursion"


leagueDate =
    case Date.fromString "2018-06-01T20:00:00.000Z" of
        Ok date ->
            date

        Err err ->
            Debug.crash "Couldn't decode a hardcoded date?" err


hidePreLeagueButton : (Date -> Route) -> H.Html msg
hidePreLeagueButton route =
    H.a [ A.class "button", Route.href <| route leagueDate ] [ Icon.fas "calendar", H.text <| " Hide pre-" ++ leagueName ++ " maps" ]


viewDateSearch : ({ after : Maybe Date, before : Maybe Date } -> Route) -> { a | before : Maybe Date, after : Maybe Date } -> H.Html msg
viewDateSearch route qs =
    let
        href0 =
            { after = Nothing, before = Nothing }

        buttons =
            case qs.after of
                Nothing ->
                    [ hidePreLeagueButton (\after -> route { href0 | after = Just after })
                    ]

                Just _ ->
                    [ H.a [ A.class "button", Route.href <| route { href0 | after = Nothing } ] [ Icon.fas "eye", H.text " Unhide all" ]
                    ]
    in
        H.span [ A.class "search-form search-date" ] buttons
