module Mapwatch.Datamine.NpcText exposing (parse)

{-| Datamined npc text isn't just plain text. It has some markup:

  - "<italics>{some-italicized-plaintext}"
  - for langs with gender conjugations, "<if:MS>{mascunline-plaintext}<if:FS>{feminine-plaintext}"

-}

import Parser as P exposing ((|.), (|=), Parser)


type Token
    = Plaintext String
    | Gendered String String
    | Italic String


parse : String -> Result String (List String)
parse =
    P.run parser
        >> Result.mapError P.deadEndsToString
        -- >> Result.mapError Debug.toString
        >> Result.map toString


toString : List Token -> List String
toString tokens =
    let
        fold : Token -> List (List String) -> List (List String)
        fold t =
            List.concatMap (fold1 t)

        fold1 : Token -> List String -> List (List String)
        fold1 t accum =
            case t of
                Plaintext s ->
                    [ s :: accum ]

                Italic s ->
                    [ s :: accum ]

                Gendered m f ->
                    [ m :: accum, f :: accum ]
    in
    tokens |> List.foldl fold [ [] ] |> List.map (List.reverse >> String.join "")


parser : P.Parser (List Token)
parser =
    let
        tokenLoop : List Token -> P.Parser (P.Step (List Token) (List Token))
        tokenLoop ts =
            P.oneOf
                [ P.succeed (\t -> P.Loop (t :: ts))
                    |= token
                , P.succeed ()
                    |> P.map (\_ -> List.reverse ts |> P.Done)
                ]
    in
    P.loop [] tokenLoop
        |. P.end


token : P.Parser Token
token =
    P.oneOf
        [ plaintext
        , italic
        , gendered
        ]


plaintext : P.Parser Token
plaintext =
    let
        create s =
            if String.length s > 0 then
                P.succeed (Plaintext s)

            else
                P.problem "empty string"
    in
    P.chompUntilEndOr "<"
        |> P.getChompedString
        |> P.andThen create


italic : P.Parser Token
italic =
    P.succeed Italic
        |. P.symbol "<italic>{"
        |= (P.chompUntil "}" |> P.getChompedString)
        |. P.symbol "}"


gendered : P.Parser Token
gendered =
    P.succeed Gendered
        |. P.symbol "<if:MS>{"
        |= (P.chompUntil "}" |> P.getChompedString)
        |. P.symbol "}"
        |. P.symbol "<elif:FS>{"
        |= (P.chompUntil "}" |> P.getChompedString)
        |. P.symbol "}"
