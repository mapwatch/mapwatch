module Model exposing
    ( Model
    , Msg(..)
    , Progress
    , init
    , subscriptions
    , update
    )

import Browser
import Browser.Navigation as Nav
import Mapwatch
import Mapwatch.Instance as Instance
import Mapwatch.LogLine as LogLine
import Mapwatch.Run as Run
import Mapwatch.Visit as Visit
import Mapwatch.Zone as Zone
import Maybe.Extra
import Ports
import Route exposing (Route)
import Set
import Task
import Time
import Url as Url exposing (Url)


type alias Flags =
    { loadedAt : Int
    , tickOffset : Int
    , isBrowserSupported : Bool
    , platform : String
    , hostname : String
    }


type alias Progress =
    Ports.Progress


type alias Config =
    { maxSize : Int }


type alias Model =
    { urlKey : Nav.Key
    , mapwatch : Mapwatch.Model
    , config : Config
    , flags : Flags
    , changelog : Maybe String
    , loadedAt : Time.Posix
    , route : Route
    , now : Time.Posix
    , tz : Time.Zone
    , lines : List String
    }


type Msg
    = M Mapwatch.Msg
    | Tick Time.Posix
    | SetTimezone Time.Zone
    | Changelog String
    | InputClientLogWithId String
    | InputMaxSize String
    | NavLocation Url
    | NavRequest Browser.UrlRequest
    | RouteTo Route
    | MapsSearch Route.MapsParams
    | HistorySearch Route.HistoryParams


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags loc urlKey =
    let
        route =
            Route.parse loc

        loadedAt =
            Time.millisToPosix flags.loadedAt

        model =
            { urlKey = urlKey
            , mapwatch = Mapwatch.initModel
            , config = { maxSize = 20 }
            , flags = flags
            , changelog = Nothing
            , loadedAt = loadedAt
            , route = route
            , now = loadedAt
            , tz = Time.utc
            , lines = []
            }
    in
    ( model, Cmd.batch [ Task.perform SetTimezone Time.here ] )


updateRawLine : { date : Int, line : String } -> Model -> Model
updateRawLine raw model =
    -- *Only when debugging*, save all raw loglines.
    case model.route of
        Route.DebugDumpLines ->
            case LogLine.parse (Time.millisToPosix raw.date) raw.line of
                Ok _ ->
                    { model | lines = raw.line :: model.lines }

                Err _ ->
                    model

        _ ->
            model


applyTimeOffset : Model -> Time.Posix -> Time.Posix
applyTimeOffset model t0 =
    (Time.posixToMillis t0 - model.flags.tickOffset)
        |> Time.millisToPosix


tick : Time.Posix -> Model -> Model
tick t0 model =
    let
        t =
            applyTimeOffset model t0
    in
    { model | mapwatch = Mapwatch.tick t model.mapwatch, now = t }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ config } as model) =
    case msg of
        Tick t ->
            if Maybe.Extra.unwrap False Mapwatch.isProgressDone model.mapwatch.progress then
                ( tick t model, Cmd.none )

            else
                ( { model | now = applyTimeOffset model t }, Cmd.none )

        SetTimezone tz ->
            ( { model | tz = tz }, Cmd.none )

        NavLocation url ->
            ( { model | route = Route.parse url }, Cmd.none )

        NavRequest req ->
            -- https://package.elm-lang.org/packages/elm/browser/latest/Browser#UrlRequest
            case req of
                Browser.Internal url ->
                    ( model, url |> Url.toString |> Nav.pushUrl model.urlKey )

                Browser.External url ->
                    ( model, url |> Nav.load )

        Changelog markdown ->
            ( { model | changelog = Just markdown }, Cmd.none )

        InputClientLogWithId id ->
            ( model, Ports.inputClientLogWithId { id = id, maxSize = config.maxSize } )

        InputMaxSize s ->
            case String.toInt s of
                Just s_ ->
                    ( { model | config = { config | maxSize = s_ } }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        MapsSearch ps ->
            ( model
            , Route.Maps ps
                |> Route.stringify
                -- |> Debug.log "maps-search"
                |> Nav.replaceUrl model.urlKey
            )

        HistorySearch ps ->
            ( model
            , Route.History ps
                |> Route.stringify
                -- |> Debug.log "history-search"
                |> Nav.replaceUrl model.urlKey
            )

        RouteTo route ->
            ( model
            , route
                |> Route.stringify
                -- |> Debug.log "route-to"
                |> Nav.replaceUrl model.urlKey
            )

        M msg_ ->
            case msg_ of
                Mapwatch.RecvLogLine raw ->
                    updateMapwatch msg_ model
                        |> Tuple.mapFirst (updateRawLine raw)

                Mapwatch.RecvProgress p ->
                    updateMapwatch (Mapwatch.RecvProgress { p | updatedAt = p.updatedAt |> Time.millisToPosix |> applyTimeOffset model |> Time.posixToMillis }) model


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
        --, Browser.Events.onAnimationFrame Tick
        , Time.every 1000 Tick
        ]
