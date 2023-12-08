module Mapwatch.Datamine.NpcText exposing (parse)

{-| Datamined npc text isn't just plain text. It has some markup:

  - "<italics>{some-italicized-plaintext}"
  - for langs with gender conjugations, "<if:MS>{mascunline-plaintext}<if:FS>{feminine-plaintext}"

-}

import List.Extra
import Parser as P exposing ((|.), (|=), Parser)


type Token
    = Plaintext String
    | Gendered String String
    | Italic String
    | Bold String
    | Newline


parse : String -> Result String (List String)
parse input =
    input
        |> P.run parser
        -- |> Result.mapError P.deadEndsToString
        -- |> Result.mapError Debug.toString
        |> Result.mapError (\e -> "NpcText parse error: \n\"" ++ input ++ "\"\n\n" ++ deadEndsToString e)
        |> Result.map toString


{-| from <https://github.com/elm/parser/pull/16/files>
-}
deadEndsToString : List P.DeadEnd -> String
deadEndsToString deadEnds =
    String.concat (List.intersperse "; " (List.map deadEndToString deadEnds))


deadEndToString : P.DeadEnd -> String
deadEndToString deadend =
    problemToString deadend.problem ++ " at row " ++ String.fromInt deadend.row ++ ", col " ++ String.fromInt deadend.col


problemToString : P.Problem -> String
problemToString p =
    case p of
        P.Expecting s ->
            "expecting '" ++ s ++ "'"

        P.ExpectingInt ->
            "expecting int"

        P.ExpectingHex ->
            "expecting hex"

        P.ExpectingOctal ->
            "expecting octal"

        P.ExpectingBinary ->
            "expecting binary"

        P.ExpectingFloat ->
            "expecting float"

        P.ExpectingNumber ->
            "expecting number"

        P.ExpectingVariable ->
            "expecting variable"

        P.ExpectingSymbol s ->
            "expecting symbol '" ++ s ++ "'"

        P.ExpectingKeyword s ->
            "expecting keyword '" ++ s ++ "'"

        P.ExpectingEnd ->
            "expecting end"

        P.UnexpectedChar ->
            "unexpected char"

        P.Problem s ->
            "problem " ++ s

        P.BadRepeat ->
            "bad repeat"


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

                Bold s ->
                    [ s :: accum ]

                Gendered m f ->
                    [ m :: accum, f :: accum ]

                Newline ->
                    [ accum ]


    in
    tokens
        -- if some npctext has multiple lines, drop everything after the first line, as loglines don't include newlines.
        -- That's good enough for matching everything we care about.
        |> List.Extra.takeWhile (\t -> t /= Newline)
        |> List.foldl fold [ [] ]
        |> List.map (List.reverse >> String.join "")


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
        , bold
        , italic
        , gendered
        , newline
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
    -- <, \n, \r
    P.chompWhile (\c -> c /= '<' && c /= '\n' && c /= '\u{000D}')
        |> P.getChompedString
        |> P.andThen create


italic : P.Parser Token
italic =
    P.succeed Italic
        |. P.oneOf
            [ P.symbol "<italic>{"
            , P.symbol "<i>{"

            -- the Thai translation of "BaranFourStoneDeatha" puts a zero-width space in the middle of this tag. Most inconvenient.
            -- https://www.fileformat.info/info/unicode/char/200b/index.htm
            , P.symbol <| "<italic\u{200B}>"
            ]
        -- |. P.symbol "<italic>{"
        |= (P.chompUntil "}" |> P.getChompedString)
        |. P.symbol "}"


bold : P.Parser Token
bold =
    P.succeed Bold
        |. P.symbol "<b>{"
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


newline : P.Parser Token
newline =
    P.succeed Newline
        -- \r\n
        |. P.symbol "\u{000D}\n"
