module Generate exposing (main)

{-| -}

import Elm
import Elm.Annotation as Type
import Gen.CodeGen.Generate as Generate
import Gen.Helper
import Json.Decode as D
import Json.Encode as E


main : Program D.Value () ()
main =
    Generate.fromJson flagsDecoder <|
        \flags ->
            [ file
            , examplesFixture flags.examples
            , datamineFixture flags.datamine
            ]


type alias Flags =
    { examples : List Example, datamine : D.Value }


type alias Example =
    { file : String, slug : String, body : String }


flagsDecoder : D.Decoder Flags
flagsDecoder =
    D.map2 Flags
        (D.map3 Example
            (D.field "file" D.string)
            (D.field "slug" D.string)
            (D.field "body" D.string)
            |> D.list
            |> D.field "examples"
        )
        (D.field "datamine" D.value)


datamineFixture : D.Value -> Elm.File
datamineFixture dm =
    Elm.file [ "Fixture", "DatamineJson" ] <|
        [ dm
            |> E.encode 2
            |> Elm.string
            |> Elm.declaration "datamine"
        ]


examplesFixture : List Example -> Elm.File
examplesFixture exs =
    Elm.file [ "Fixture", "Examples" ] <|
        [ Elm.alias "Example" <|
            Type.record
                [ ( "slug", Type.string )
                , ( "file", Type.string )
                , ( "body", Type.string )
                ]
        , exs
            |> List.map
                (\ex ->
                    [ ( "slug", Elm.string ex.slug )
                    , ( "file", Elm.string ex.file )
                    , ( "body", Elm.value { name = ex.slug, importFrom = [], annotation = Nothing } )
                    ]
                        |> Elm.record
                        |> Elm.withType (Type.named [] "Example")
                )
            |> Elm.list
            |> Elm.declaration "list_"
        ]
            ++ (exs |> List.map (\ex -> Elm.declaration ex.slug <| Elm.string ex.body))


file : Elm.File
file =
    Elm.file [ "HelloWorld" ]
        [ Elm.declaration "hello"
            (Elm.string "World!")

        -- Here's an example of using a helper file!
        -- Add functions to codegen/helpers/{Whatever}.elm
        -- run elm-codegen install
        -- Then you can call those functions using import Gen.{Whatever}
        , Elm.declaration "usingAHelper"
            (Gen.Helper.add5 20)
        ]
