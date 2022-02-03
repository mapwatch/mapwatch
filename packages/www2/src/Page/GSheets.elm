module Page.GSheets exposing (view)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import ISO8601
import Json.Encode as E
import Mapwatch
import Mapwatch.MapRun as MapRun exposing (MapRun)
import Maybe.Extra
import Model exposing (Msg, OkModel)
import Page.History
import Page.NotFound
import RemoteData exposing (RemoteData)
import Route exposing (Route)
import Route.Feature as Feature exposing (Feature)
import Time exposing (Posix)
import View.Home
import View.Icon
import View.Nav
import View.Setup
import View.Spreadsheet as Spreadsheet


view : OkModel -> Html Msg
view model =
    if Feature.isActive Feature.GSheets model.query then
        div [ class "main" ]
            [ View.Home.viewHeader model
            , View.Nav.view model
            , View.Setup.view model
            , viewBody model
            ]

    else
        Page.NotFound.view model


viewBody : OkModel -> Html Msg
viewBody model =
    case Mapwatch.ready model.mapwatch of
        Mapwatch.NotStarted ->
            div [] []

        Mapwatch.LoadingHistory p ->
            View.Home.viewProgress p

        Mapwatch.Ready p ->
            div [] <|
                [ div [ class "beta-alert" ]
                    [ View.Icon.fas "exclamation-triangle"
                    , text " Beware: Mapwatch's Google Sheets export is new "
                    , br [] []
                    , text "and still only "
                    , code [] [ text "BETA" ]
                    , text " quality. Expect bugs."
                    ]
                ]
                    ++ viewMain model


viewMain : OkModel -> List (Html Msg)
viewMain model =
    case model.gsheets of
        RemoteData.NotAsked ->
            [ p [] [ text "Login to your Google account below to create a spreadsheet with your Mapwatch data." ]
            , button [ onClick Model.GSheetsLogin ] [ text "Login to Google Sheets" ]
            , p [] [ a [ Route.href model.query Route.Privacy ] [ text "Mapwatch Privacy Policy" ] ]
            ]

        RemoteData.Loading ->
            [ button [ disabled True ] [ View.Icon.fasPulse "spinner", text " Login to Google Sheets" ]
            , p [] [ a [ Route.href model.query Route.Privacy ] [ text "Mapwatch Privacy Policy" ] ]
            ]

        RemoteData.Failure err ->
            [ button [ onClick Model.GSheetsLogin ] [ text "Login to Google Sheets" ]
            , pre [] [ text err ]
            , p [] [ a [ Route.href model.query Route.Privacy ] [ text "Mapwatch Privacy Policy" ] ]
            ]

        RemoteData.Success gsheets ->
            let
                runs =
                    Page.History.listRuns model
            in
            [ div []
                [ case ( gsheets.url, model.settings.spreadsheetId ) of
                    ( RemoteData.Loading, _ ) ->
                        button [ disabled True ]
                            [ View.Icon.fasPulse "spinner", text <| " Write " ++ String.fromInt (List.length runs) ++ " maps to spreadsheet id: " ]

                    ( _, Nothing ) ->
                        button [ onClick <| gsheetsWrite model runs Nothing ]
                            [ text <| "Write " ++ String.fromInt (List.length runs) ++ " maps to a new spreadsheet" ]

                    ( _, Just id ) ->
                        button [ onClick <| gsheetsWrite model runs (Just id) ]
                            [ text <| "Write " ++ String.fromInt (List.length runs) ++ " maps to spreadsheet id: " ]
                , input
                    [ type_ "text"
                    , value <| Maybe.withDefault "" model.settings.spreadsheetId
                    , onInput Model.InputSpreadsheetId
                    ]
                    []
                ]
            , case gsheets.url of
                RemoteData.NotAsked ->
                    p [] []

                RemoteData.Loading ->
                    p [] [ View.Icon.fasPulse "spinner" ]

                RemoteData.Failure err ->
                    p [] [ pre [] [ text err ] ]

                RemoteData.Success url ->
                    p []
                        [ text "Export successful! "
                        , a [ target "_blank", href url ] [ text "View your spreadsheet." ]
                        ]
            , p []
                [ button [ onClick Model.GSheetsLogout ]
                    [ text "Logout of Google Sheets" ]
                ]
            , p []
                [ button [ onClick Model.GSheetsDisconnect ]
                    [ text "Disconnect Google Sheets" ]
                , div [] [ small [] [ text " Log out everywhere, and remove Mapwatch from your Google account." ] ]
                ]
            , p [] [ a [ Route.href model.query Route.Privacy ] [ text "Mapwatch Privacy Policy" ] ]
            ]


gsheetsWrite : OkModel -> List MapRun -> Maybe String -> Msg
gsheetsWrite model runs spreadsheetId =
    Model.GSheetsWrite
        { spreadsheetId = spreadsheetId
        , title = "Mapwatch"
        , content =
            [ Spreadsheet.viewHistory model runs
            , Spreadsheet.viewMaps model runs
            , Spreadsheet.viewEncounters model runs
            ]
                |> List.map encodeSheet
        }


encodeSheet : Spreadsheet.Sheet -> Model.Sheet
encodeSheet s =
    { title = s.title
    , headers = s.headers
    , rows = s.rows |> List.map (List.map encodeCell)
    }


encodeCell : Spreadsheet.Cell -> E.Value
encodeCell c =
    -- https://developers.google.com/sheets/api/reference/rest/v4/spreadsheets/other#ExtendedValue
    case c of
        Spreadsheet.CellEmpty ->
            stringValue ""

        Spreadsheet.CellString s ->
            stringValue s

        Spreadsheet.CellDuration d ->
            stringValue <| View.Home.formatDuration d

        Spreadsheet.CellPosix tz d ->
            posixValue tz d

        Spreadsheet.CellBool b ->
            boolValue b

        Spreadsheet.CellInt n ->
            numberValue <| toFloat n

        Spreadsheet.CellFloat n ->
            numberValue n

        Spreadsheet.CellPercent n ->
            percentValue n

        Spreadsheet.CellIcon src ->
            formulaValue <| "=IMAGE(\"" ++ src ++ "\")"


cellValue : String -> E.Value -> E.Value
cellValue k v =
    E.object [ ( "userEnteredValue", E.object [ ( k, v ) ] ) ]


posixValue : Time.Zone -> Posix -> E.Value
posixValue tz d =
    let
        t =
            Spreadsheet.posixToString tz d
    in
    E.object
        -- [ ( "userEnteredValue", E.object [ ( "formulaValue", E.string <| "=TO_DATE(DATEVALUE(\"" ++ t ++ "\") + TIMEVALUE(\"" ++ t ++ "\"))" ) ] )
        [ ( "userEnteredValue", E.object [ ( "stringValue", E.string t ) ] )
        , ( "userEnteredFormat", E.object [ ( "numberFormat", E.object [ ( "type", E.string "DATE_TIME" ) ] ) ] )
        ]


stringValue : String -> E.Value
stringValue s =
    cellValue "stringValue" <| E.string s


boolValue : Bool -> E.Value
boolValue b =
    if b then
        cellValue "boolValue" <| E.bool b

    else
        stringValue ""


percentValue : Float -> E.Value
percentValue n =
    formulaValue <| "=TO_PERCENT(" ++ String.fromFloat n ++ ")"


numberValue : Float -> E.Value
numberValue n =
    cellValue "numberValue" <| E.float n


formulaValue : String -> E.Value
formulaValue f =
    cellValue "formulaValue" <| E.string f
