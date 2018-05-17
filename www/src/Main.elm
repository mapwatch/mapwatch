module Main exposing (main)

import Ports
import Html as H
import Html.Attributes as A
import Html.Events as E


main =
    H.programWithFlags
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type alias Flags =
    { wshost : String
    }


type alias Model =
    { lines : List String
    , config : Ports.Config
    }


type Msg
    = StartWatching
    | InputClientLogPath String
    | LogLine String


initModel : Flags -> Model
initModel flags =
    { lines = []
    , config =
        { wshost = flags.wshost
        , clientLogPath = "../Client.txt"
        }
    }


init flags =
    initModel flags
        |> update StartWatching


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StartWatching ->
            ( model, Ports.startWatching model.config )

        InputClientLogPath path ->
            let
                config =
                    model.config
            in
                ( { model | config = { config | clientLogPath = path } }, Cmd.none )

        LogLine line ->
            ( { model | lines = line :: model.lines }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.logline LogLine
        ]


viewLogLine : String -> H.Html msg
viewLogLine str =
    H.li [] [ H.text str ]


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


view : Model -> H.Html Msg
view model =
    H.div []
        [ H.text "Hello elm-world!"
        , viewConfig model
        , H.ul [] (List.map viewLogLine model.lines)
        ]
