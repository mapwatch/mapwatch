module Main exposing (main)

import Http
import Json.Decode as Json


type alias Model =
    {}


type Msg
    = RecvCharacterWindowGetItems (Result Http.Error String)


init =
    ( {}, Http.send RecvCharacterWindowGetItems <| fetchItems "ButImACreep" )


fetchItems char =
    Http.getString <| "https://pathofexile.com/character-window/get-items?character=" ++ Http.encodeUri char


update msg model =
    Debug.log "msg" msg
        |> \_ ->
            ( model, Cmd.none )


subscriptions model =
    Sub.batch []


main =
    Platform.program
        { init = init
        , update = update
        , subscriptions = subscriptions
        }
