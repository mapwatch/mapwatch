module Model
    exposing
        ( Model
        , Msg(..)
        , Progress
        , init
        , initModel
        , update
        , subscriptions
        )

import Set
import Date
import Time
import Maybe.Extra
import AnimationFrame
import Navigation
import Ports
import Mapwatch
import Mapwatch.LogLine as LogLine
import Mapwatch.Zone as Zone
import Mapwatch.Instance as Instance
import Mapwatch.Visit as Visit
import Mapwatch.Run as Run
import Route exposing (Route)


type alias Flags =
    { loadedAt : Float
    , tickOffset : Float
    , isBrowserSupported : Bool
    }


type alias Progress =
    Ports.Progress


type alias Config =
    { maxSize : Int }


type alias Model =
    { mapwatch : Mapwatch.Model
    , config : Config
    , flags : Flags
    , changelog : Maybe String
    , loadedAt : Date.Date
    , route : Route
    , now : Date.Date
    , lines : List String
    }


type Msg
    = M Mapwatch.Msg
    | Tick Time.Time
    | Changelog String
    | InputClientLogWithId String
    | InputMaxSize String
    | Navigate Navigation.Location
    | RouteTo Route
    | MapsSearch Route.MapsParams
    | HistorySearch Route.HistoryParams


initModel : Flags -> Route -> Model
initModel flags route =
    let
        loadedAt =
            Date.fromTime flags.loadedAt
    in
        { mapwatch = Mapwatch.initModel
        , config = { maxSize = 20 }
        , flags = flags
        , changelog = Nothing
        , loadedAt = loadedAt
        , route = route
        , now = loadedAt
        , lines = []
        }


init flags loc =
    ( initModel flags (Route.parse loc), Cmd.none )


updateRawLine : String -> Model -> Model
updateRawLine raw model =
    -- *Only when debugging*, save all raw loglines.
    case model.route of
        Route.DebugDumpLines ->
            case LogLine.parse raw of
                Ok _ ->
                    { model | lines = raw :: model.lines }

                Err _ ->
                    model

        _ ->
            model


applyTimeOffset : Model -> Time.Time -> Time.Time
applyTimeOffset model t0 =
    t0 - model.flags.tickOffset


tick : Time.Time -> Model -> Model
tick t0 model =
    let
        t =
            applyTimeOffset model t0
    in
        { model | mapwatch = Mapwatch.tick t model.mapwatch, now = Date.fromTime t }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ config } as model) =
    case msg of
        Tick t ->
            if Maybe.Extra.unwrap False Mapwatch.isProgressDone model.mapwatch.progress then
                ( tick t model, Cmd.none )
            else
                ( { model | now = Date.fromTime <| applyTimeOffset model t }, Cmd.none )

        Navigate loc ->
            ( { model | route = Route.parse loc }, Cmd.none )

        Changelog markdown ->
            ( { model | changelog = Just markdown }, Cmd.none )

        InputClientLogWithId id ->
            ( model, Ports.inputClientLogWithId { id = id, maxSize = config.maxSize } )

        InputMaxSize s ->
            case String.toInt s of
                Ok s ->
                    ( { model | config = { config | maxSize = s } }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        MapsSearch ps ->
            ( model
            , Route.Maps ps
                |> Route.stringify
                -- |> Debug.log "maps-search"
                |> Navigation.modifyUrl
            )

        HistorySearch ps ->
            ( model
            , Route.History ps
                |> Route.stringify
                -- |> Debug.log "history-search"
                |> Navigation.modifyUrl
            )

        RouteTo route ->
            ( model
            , route
                |> Route.stringify
                -- |> Debug.log "route-to"
                |> Navigation.modifyUrl
            )

        M msg ->
            case msg of
                Mapwatch.RecvLogLine raw ->
                    updateMapwatch msg model
                        |> Tuple.mapFirst (updateRawLine raw)

                Mapwatch.RecvProgress p ->
                    updateMapwatch (Mapwatch.RecvProgress { p | updatedAt = applyTimeOffset model p.updatedAt }) model


updateMapwatch : Mapwatch.Msg -> Model -> ( Model, Cmd Msg )
updateMapwatch msg model =
    let
        ( mapwatch, cmd ) =
            Mapwatch.update msg model.mapwatch
    in
        ( { model | mapwatch = mapwatch }, Cmd.map M cmd )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Mapwatch.subscriptions model.mapwatch |> Sub.map M
        , Ports.changelog Changelog

        -- Slow down animation, deliberately - don't eat poe's cpu
        -- , AnimationFrame.times Tick
        , Time.every (Time.second * 1) Tick
        ]
