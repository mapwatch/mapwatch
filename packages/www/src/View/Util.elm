module View.Util exposing (hidePreLeagueButton, leagueDate, leagueName, pluralize, roundToPlaces, viewDateSearch, viewGoalForm, viewSearch)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import ISO8601
import Mapwatch exposing (Model, Msg)
import Regex
import Route as Route exposing (Route)
import Time exposing (Posix)
import View.Icon as Icon


roundToPlaces : Float -> Float -> Float
roundToPlaces p n =
    (n * (10 ^ p) |> round |> toFloat) / (10 ^ p)


viewSearch : List (Attribute msg) -> (String -> msg) -> Maybe String -> Html msg
viewSearch attrs msg search =
    span [ class "search-form search-text" ]
        [ input
            ([ value <| Maybe.withDefault "" search
             , type_ "text"
             , tabindex 1
             , onInput msg
             ]
                ++ attrs
            )
            []
        , Icon.fas "search"
        ]


viewGoalForm : (Maybe String -> msg) -> { a | goal : Maybe String, after : Maybe b, enableGoals : Bool } -> Html msg
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
                        if Regex.contains ("best|mean|none" |> Regex.fromString |> Maybe.withDefault Regex.never) dur then
                            Nothing

                        else
                            Just ( [ selected True ], [ input [ type_ "text", onInput onChange, value dur, placeholder "\"5:00\" or \"300\" or \"5m 0s\"" ] [] ] )
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
        span [ class "search-form search-goal" ]
            [ select [ onInput onChange ]
                [ option [ selected <| qs.goal == Nothing || qs.goal == Just "none", value "none" ] [ text "No time goal" ]
                , option [ selected <| qs.goal == Just "best-session", value "best-session" ] [ text <| "Goal: " ++ sessionName ++ " best" ]
                , option [ selected <| qs.goal == Just "best", value "best" ] [ text <| "Goal: all-time best" ]
                , option [ selected <| qs.goal == Just "mean-session", value "mean-session" ] [ text <| "Goal: " ++ sessionName ++ " average" ]
                , option [ selected <| qs.goal == Just "mean", value "mean" ] [ text <| "Goal: all-time average" ]
                , option (optExactly ++ [ value "" ]) [ text "Goal: exactly..." ]
                ]
            , span [] exactly
            ]

    else
        span [] []


pluralize : String -> String -> number -> String
pluralize one other n =
    if n == 1 then
        one

    else
        other


leagueName =
    "Metamorph"


leagueDate : Result String Posix
leagueDate =
    "2019-12-13T20:00:00.000Z" |> ISO8601.fromString |> Result.map ISO8601.toPosix


hidePreLeagueButton : (Posix -> Route) -> Html msg
hidePreLeagueButton route =
    case leagueDate of
        Err err ->
            pre [] [ text err ]

        Ok date ->
            a [ class "button", Route.href <| route date ] [ Icon.fas "calendar", text <| " Hide pre-" ++ leagueName ++ " maps" ]


viewDateSearch : ({ after : Maybe Posix, before : Maybe Posix } -> Route) -> { a | before : Maybe Posix, after : Maybe Posix } -> Html msg
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
                    [ a [ class "button", Route.href <| route { href0 | after = Nothing } ] [ Icon.fas "eye", text " Unhide all" ]
                    ]
    in
    span [ class "search-form search-date" ] buttons
