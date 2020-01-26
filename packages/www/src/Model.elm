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
import Mapwatch.MapRun as MapRun exposing (MapRun)
import Mapwatch.Visit as Visit
import Maybe.Extra
import Ports
import RemoteData exposing (RemoteData)
import Route exposing (Route)
import Route.Feature as Feature exposing (Feature)
import Route.QueryDict as QueryDict exposing (QueryDict)
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
    , query : QueryDict
    , now : Posix
    , lines : List String
    , settings : Settings
    , tz : Time.Zone
    , gsheets : RemoteData String GSheetsSession
    }


type alias GSheetsSession =
    { url : RemoteData String String }


type Msg
    = M Mapwatch.Msg
    | Tick Posix
    | SetTimezone Time.Zone
    | LogSelected String
    | InputMaxSize String
    | NavRequest Browser.UrlRequest
    | NavLocation Url
    | RouteTo Route
    | Search QueryDict
    | InputVolume String
    | InputSpreadsheetId String
    | Reset (Maybe Route)
    | GSheetsLoginUpdate { login : Maybe Bool, error : Maybe String }
    | GSheetsLogin
    | GSheetsLogout
    | GSheetsWrite { spreadsheetId : Maybe String, headers : List String, rows : List (List String) }
    | GSheetsWritten { res : Maybe { spreadsheetUrl : String, spreadsheetId : String }, error : Maybe String }


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url nav =
    let
        ( route, query ) =
            Route.parse url

        model =
            reset flags
                nav
                query
                route
                (flags.settings
                    |> D.decodeValue Settings.decoder
                    |> Result.withDefault Settings.empty
                    |> (\s ->
                            if Feature.isActive Feature.Speech query then
                                s

                            else
                                { s | volume = 0 }
                       )
                )
                -- placeholder; Time.here and SetTimezone set this shortly
                -- TODO Maybe type?
                Time.utc
                RemoteData.NotAsked
    in
    ( model
    , Cmd.batch
        [ Task.perform SetTimezone Time.here
        , model |> Result.map sendSettings |> Result.withDefault Cmd.none
        ]
    )


reset : Flags -> Nav.Key -> QueryDict -> Route -> Settings -> Time.Zone -> RemoteData String GSheetsSession -> Model
reset flags nav query route settings tz gsheets =
    let
        loadedAt =
            Time.millisToPosix flags.loadedAt

        logtz : Maybe Time.Zone
        logtz =
            flags.logtz |> Maybe.map (\offset -> Time.customZone (60 * offset |> round) [])

        createModel : Mapwatch.OkModel -> OkModel
        createModel mapwatch =
            { nav = nav
            , mapwatch = mapwatch
            , config = { maxSize = 20 }
            , flags = flags
            , loadedAt = loadedAt
            , route = route
            , query = query
            , now = loadedAt
            , lines = []
            , settings = settings
            , tz = tz
            , gsheets = gsheets
            }
    in
    Result.map createModel
        (Mapwatch.initModel logtz flags.datamine)


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
                ( route, query ) =
                    Route.parse url

                newModel =
                    { model | route = route, query = query }
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

        Search query ->
            ( model
            , Route.replaceUrl model.nav query model.route
            )

        RouteTo route ->
            ( model
            , Route.replaceUrl model.nav model.query route
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

        InputSpreadsheetId str ->
            let
                newModel =
                    { model
                        | settings =
                            { settings
                                | spreadsheetId =
                                    if str == "" then
                                        Nothing

                                    else
                                        Just str
                            }
                    }
            in
            ( newModel, sendSettings newModel )

        GSheetsLogin ->
            ( { model | gsheets = RemoteData.Loading }, Ports.gsheetsLogin () )

        GSheetsLogout ->
            ( { model | gsheets = RemoteData.Loading }, Ports.gsheetsLogout () )

        GSheetsLoginUpdate res ->
            ( { model
                | gsheets =
                    case ( res.error, res.login ) of
                        ( Just error, _ ) ->
                            RemoteData.Failure error

                        ( Nothing, Just True ) ->
                            RemoteData.Success { url = RemoteData.NotAsked }

                        ( Nothing, Just False ) ->
                            RemoteData.NotAsked

                        ( Nothing, Nothing ) ->
                            RemoteData.Failure "empty login response"
              }
            , Cmd.none
            )

        GSheetsWrite args ->
            case model.gsheets of
                RemoteData.Success gsheets ->
                    ( { model | gsheets = RemoteData.Success { gsheets | url = RemoteData.Loading } }, Ports.gsheetsWrite args )

                _ ->
                    ( model, Cmd.none )

        GSheetsWritten result ->
            case model.gsheets of
                RemoteData.Success gsheets ->
                    let
                        m =
                            { model
                                | gsheets =
                                    RemoteData.Success
                                        { gsheets
                                            | url =
                                                case ( result.res |> Maybe.map .spreadsheetUrl, result.error ) of
                                                    ( _, Just error ) ->
                                                        RemoteData.Failure error

                                                    ( Just url, Nothing ) ->
                                                        RemoteData.Success url

                                                    ( Nothing, Nothing ) ->
                                                        RemoteData.Failure "empty spreadsheet.create response"
                                        }
                                , settings =
                                    case result.res |> Maybe.map .spreadsheetId of
                                        Nothing ->
                                            settings

                                        Just id ->
                                            { settings | spreadsheetId = Just id }
                            }
                    in
                    ( m, Ports.sendSettings m.settings )

                _ ->
                    ( model, Cmd.none )

        Reset redirect ->
            ( reset model.flags model.nav model.query model.route model.settings model.tz model.gsheets
                |> Result.withDefault model
            , Maybe.Extra.unwrap Cmd.none (Route.pushUrl model.nav model.query) redirect
            )

        M msg_ ->
            updateMapwatch msg_ model


updateMapwatch : Mapwatch.Msg -> OkModel -> ( OkModel, Cmd Msg )
updateMapwatch msg model =
    let
        ( mapwatch, cmd ) =
            Mapwatch.updateOk model.settings msg model.mapwatch
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
                , Ports.gsheetsLoginUpdate GSheetsLoginUpdate
                , Ports.gsheetsWritten GSheetsWritten

                -- Slow down animation, deliberately - don't eat poe's cpu
                --, Browser.Events.onAnimationFrame Tick
                , Time.every 1000 Tick
                ]
