port module JestMain exposing (main)

import Json.Decode as D
import Json.Encode as E
import Mapwatch
import Mapwatch.Datamine as Datamine exposing (Datamine)
import Mapwatch.MapRun as MapRun exposing (MapRun)
import Settings
import Time


main : Program Flags Model Msg
main =
    Platform.worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }


type alias Flags =
    { datamine : D.Value }


type alias Model =
    { datamine : Result D.Error Datamine }


type Msg
    = Noop
    | MapRunSub { body : String }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        datamine =
            D.decodeValue Datamine.decoder flags.datamine

        cmd =
            case datamine of
                Ok _ ->
                    { status = "ready", message = Nothing }

                Err err ->
                    { status = "error", message = err |> D.errorToString |> Just }
    in
    ( { datamine = datamine }, initCmd cmd )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model.datamine of
        Err err ->
            ( model, Cmd.none )

        Ok dm ->
            case msg of
                Noop ->
                    ( model, Cmd.none )

                MapRunSub m ->
                    let
                        body =
                            m.body |> mapRuns dm |> Debug.toString |> E.string
                    in
                    ( model, { status = "success", body = Just body } |> mapRunCmd )


mapRuns : Datamine -> String -> List MapRun
mapRuns datamine =
    Mapwatch.fromLogSlice (Just Time.utc) datamine Settings.empty 0 >> .runs


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch [ mapRunSub MapRunSub ]


port initCmd : { status : String, message : Maybe String } -> Cmd msg


port mapRunSub : ({ body : String } -> msg) -> Sub msg


port mapRunCmd : { status : String, body : Maybe D.Value } -> Cmd msg
