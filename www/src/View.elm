module View exposing (view)

import Html as H
import Html.Attributes as A
import Html.Events as E
import LogLine
import Model as Model exposing (Model, Msg(..))


viewLogLine : LogLine.Line -> H.Html msg
viewLogLine line =
    H.li []
        [ H.text (toString line.date)
        , H.text (toString line.info)
        , H.div [] [ H.i [] [ H.text line.raw ] ]
        ]


instanceToString : Maybe Model.Instance -> String
instanceToString instance =
    case instance of
        Just i ->
            i.zone ++ "@" ++ i.addr

        Nothing ->
            "(none)"


viewInstanceEntry : Model.InstanceEntry -> H.Html msg
viewInstanceEntry entry =
    H.li []
        [ H.text <|
            toString entry.at
                ++ ": "
                ++ toString entry.dur
                ++ "ms"
                ++ (if entry.last then
                        "????"
                    else
                        ""
                   )
                ++ ", "
                ++ instanceToString entry.instance
        ]


viewCurrentInstance : Maybe Model.CurrentInstance -> H.Html msg
viewCurrentInstance cur =
    case cur of
        Just entry ->
            H.ul [] [ H.li [] [ H.text <| toString entry.at ++ ": (now), " ++ instanceToString entry.instance ] ]

        Nothing ->
            H.ul [] [ H.li [] [ H.text "(none yet)" ] ]


viewConfig : Model -> H.Html Msg
viewConfig model =
    H.form [ E.onSubmit StartWatching ]
        [ H.div []
            [ H.text "local log server: "
            , H.input [ A.disabled True, A.type_ "text", A.value model.config.wshost ] []
            ]
        , H.div []
            [ H.text "path to PoE Client.txt: "
            , H.input [ A.type_ "text", E.onInput InputClientLogPath, A.value model.config.clientLogPath ] []
            ]
        , H.div [] [ H.button [ A.type_ "submit" ] [ H.text "Watch" ] ]
        ]


viewParseError : Maybe LogLine.ParseError -> H.Html msg
viewParseError err =
    case err of
        Nothing ->
            H.div [] []

        Just err ->
            H.div [] [ H.text <| "Log parsing error: " ++ toString err ]


view : Model -> H.Html Msg
view model =
    H.div []
        [ H.text "Hello elm-world!"
        , viewConfig model
        , H.text "instance-entries:"
        , viewCurrentInstance model.current
        , H.ul [] (List.map viewInstanceEntry model.entries)
        , viewParseError model.parseError
        , H.text "linebuf:"
        , H.ul [] (List.map viewLogLine model.linebuf)
        ]
