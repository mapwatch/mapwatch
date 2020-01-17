module Model exposing
    ( Model
    , Msg(..)
    , OkModel
    , Progress
    , init
    , subscriptions
    , update
    )

import Browser
import Browser.Navigation as Nav
import Json.Decode as D
import Mapwatch
import Mapwatch.Datamine as Datamine exposing (Datamine)
import Mapwatch.Instance as Instance
import Mapwatch.LogLine as LogLine
import Mapwatch.Run as Run
import Mapwatch.Visit as Visit
import Maybe.Extra
import Ports
import Route exposing (Route)
import Set
import Settings exposing (Settings)
import Task
import Time exposing (Posix)
import Url exposing (Url)


type alias Flags =
    { loadedAt : Int
    , tickOffset : Int
    , isBrowserSupported : Bool
    , platform : String
    , changelog : String
    , version : String
    , datamine : D.Value
    , logtz : Maybe Float
    , settings : D.Value
    }


type alias Progress =
    Ports.Progress


type alias Config =
    { maxSize : Int }


type alias Model =
    Result String OkModel


type alias OkModel =
    { nav : Nav.Key
    , mapwatch : Mapwatch.OkModel
    , config : Config
    , flags : Flags
    , loadedAt : Posix
    , route : Route
    , now : Posix
    , lines : List String
    , settings : Settings
    , tz : Time.Zone
    }


type Msg
    = M Mapwatch.Msg
    | Tick Posix
    | SetTimezone Time.Zone
    | LogSelected String
    | InputMaxSize String
    | NavRequest Browser.UrlRequest
    | NavLocation Url
    | RouteTo Route
    | MapsSearch Route.MapsParams
    | HistorySearch Route.HistoryParams
    | InputVolume String


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url nav =
    let
        loadedAt =
            Time.millisToPosix flags.loadedAt

        logtz : Maybe Time.Zone
        logtz =
            flags.logtz |> Maybe.map (\offset -> Time.customZone (60 * offset |> round) [])

        settings : Settings
        settings =
            flags.settings
                |> D.decodeValue Settings.decoder
                |> Result.withDefault Settings.empty

        createModel : Mapwatch.OkModel -> OkModel
        createModel mapwatch =
            { nav = nav
            , mapwatch = mapwatch
            , config = { maxSize = 20 }
            , flags = flags
            , loadedAt = loadedAt
            , route = Route.parse url
            , now = loadedAt
            , lines = []
            , settings = settings

            -- Time.here and SetTimezone set this shortly
            , tz = Time.utc
            }

        model : Model
        model =
            Result.map createModel
                (Mapwatch.initModel logtz flags.datamine)
    in
    ( model
    , Cmd.batch
        [ Task.perform SetTimezone Time.here
        , model |> Result.map sendSettings |> Result.withDefault Cmd.none
        ]
    )


sendSettings : OkModel -> Cmd msg
sendSettings model =
    Ports.sendSettings model.settings


applyTimeOffset : OkModel -> Posix -> Posix
applyTimeOffset model t0 =
    (Time.posixToMillis t0 - model.flags.tickOffset)
        |> Time.millisToPosix


tick : Posix -> OkModel -> OkModel
tick t0 model =
    let
        t =
            applyTimeOffset model t0
    in
    { model | mapwatch = Mapwatch.tick t model.mapwatch, now = t }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg rmodel =
    case rmodel of
        Err err ->
            ( rmodel, Cmd.none )

        Ok model ->
            updateOk msg model |> Tuple.mapFirst Ok


updateOk : Msg -> OkModel -> ( OkModel, Cmd Msg )
updateOk msg ({ config, mapwatch, settings } as model) =
    case msg of
        Tick t ->
            if Mapwatch.isReady model.mapwatch then
                ( tick t model, Cmd.none )

            else
                ( { model | now = applyTimeOffset model t }, Cmd.none )

        SetTimezone tz ->
            ( { model
                -- Why two timezone fields?
                --
                -- * model.tz is the timezone set in the browser. It's set
                -- automatically by Time.here, and cannot be overridden -
                -- it's pretty consistently what the user wants to see.
                --
                -- * model.mapwatch.tz is the timezone used for log parsing.
                -- PoE logs do not include timezone information! Usually we'll
                -- assume it matches the system timezone and set it here.
                -- Usually that works. It doesn't work if the user changes
                -- their timezone, for example while traveling (can't do much
                -- about that). It also doesn't work for our example logs.
                --
                -- `?logtz=-4` overrides the backend log.
                | mapwatch = { mapwatch | tz = mapwatch.tz |> Maybe.Extra.orElse (Just tz) }
                , tz = tz
              }
            , Cmd.none
            )

        NavLocation url ->
            let
                newModel =
                    { model | route = Route.parse url }
            in
            ( newModel, sendSettings newModel )

        NavRequest (Browser.Internal url) ->
            ( model, url |> Url.toString |> Nav.pushUrl model.nav )

        NavRequest (Browser.External urlstr) ->
            ( model, urlstr |> Nav.load )

        LogSelected id ->
            ( model, Ports.logSelected { id = id, maxSize = config.maxSize } )

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
                |> Nav.replaceUrl model.nav
            )

        HistorySearch ps ->
            ( model
            , Route.History ps
                |> Route.stringify
                -- |> Debug.log "history-search"
                |> Nav.replaceUrl model.nav
            )

        RouteTo route ->
            ( model
            , route
                |> Route.stringify
                -- |> Debug.log "route-to"
                |> Nav.replaceUrl model.nav
            )

        InputVolume str ->
            case str |> String.toInt of
                Nothing ->
                    ( model, Cmd.none )

                Just volume ->
                    let
                        newModel =
                            { model | settings = { settings | volume = volume } }
                    in
                    ( newModel, sendSettings newModel )

        M msg_ ->
            updateMapwatch msg_ model


updateMapwatch : Mapwatch.Msg -> OkModel -> ( OkModel, Cmd Msg )
updateMapwatch msg model =
    let
        ( mapwatch, cmd ) =
            Mapwatch.updateOk msg model.mapwatch
    in
    ( { model | mapwatch = mapwatch }, Cmd.map M cmd )
        |> Tuple.mapFirst
            (\m ->
                -- just after we finish processing history, send mapwatch the first tick so timeOffset is immediately applied
                if not (Mapwatch.isReady model.mapwatch) && Mapwatch.isReady mapwatch then
                    tick m.now m

                else
                    m
            )


subscriptions : Model -> Sub Msg
subscriptions rmodel =
    case rmodel of
        Err err ->
            Sub.none

        Ok model ->
            Sub.batch
                [ Mapwatch.subscriptions (Ok model.mapwatch) |> Sub.map M

                -- Slow down animation, deliberately - don't eat poe's cpu
                --, Browser.Events.onAnimationFrame Tick
                , Time.every 1000 Tick
                ]
