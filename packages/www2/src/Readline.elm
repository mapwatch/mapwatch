module Readline exposing
    ( Progress
    , Readline
    , create
    , isDone
    , next
    , progress
    , read
    , resize
    , size
    )

import Bytes.Encode


megabyte : Int
megabyte =
    2 ^ 20


chunkSize : Int
chunkSize =
    1 * megabyte


type alias Readline =
    { start : Int
    , end : Int
    , cursor : Int

    -- Partial line leftover from the last chunk
    , lineBuffer : String
    }


create : { start : Int, end : Int } -> Readline
create { start, end } =
    { start = start
    , end = end
    , cursor = start
    , lineBuffer = ""
    }


size : Readline -> Int
size { start, end } =
    end - start


type alias Progress =
    { percent : Float
    , max : Int
    , value : Int
    , isDone : Bool
    }


progress : Readline -> Progress
progress r =
    { percent = (toFloat r.cursor - toFloat r.start) / (toFloat r.end - toFloat r.start)
    , max = size r
    , value = r.cursor - r.start
    , isDone = isDone r
    }


isDone : Readline -> Bool
isDone r =
    r.cursor >= r.end


resize : Int -> Readline -> Result String Readline
resize end reader =
    if end < reader.end then
        Err "Readline cannot handle shrinking files"

    else if end == reader.end then
        Ok reader

    else if isDone reader then
        -- end > reader.end; the file has grown.
        -- we're done processing, but will have more to process after resizing,
        -- so update our start point
        Ok { reader | end = end, start = reader.end }

    else
        -- end > reader.end; the file has grown.
        -- we're not yet done processing it, so don't mess with our start point.
        Ok { reader | end = end }


{-| The offsets for the next chunk of the file we're requesting
-}
next : Readline -> Maybe { position : Int, length : Int }
next r =
    if isDone r then
        Nothing

    else
        Just { position = r.cursor, length = min chunkSize (r.end - r.cursor) }


{-| Receive a chunk of text and parse it into lines
-}
read : Int -> String -> Readline -> ( List ( Int, String ), Readline )
read pos0 chunk reader =
    case reader.lineBuffer ++ chunk |> String.split "\n" |> List.reverse of
        -- this is impossible, string.split/string.lines never return an empty list
        [] ->
            ( [], reader )

        last :: rlines ->
            let
                fold : String -> ( Int, List ( Int, String ) ) -> ( Int, List ( Int, String ) )
                fold line0 ( pos, accum ) =
                    let
                        ( sepsize, line ) =
                            -- detect and normalize windows line endings.
                            -- elm-format is reformatting my \r
                            if String.endsWith "\u{000D}" line0 then
                                ( 2, line0 |> String.dropRight 1 )

                            else
                                ( 1, line0 )
                    in
                    ( pos + Bytes.Encode.getStringWidth line + sepsize, ( pos, line ) :: accum )

                _ =
                    rlines
                        |> List.reverse
                        |> List.foldl fold ( reader.cursor - Bytes.Encode.getStringWidth reader.lineBuffer, [] )
                        |> Tuple.second
                        |> List.reverse
            in
            ( rlines
                |> List.reverse
                |> List.foldl fold ( reader.cursor - Bytes.Encode.getStringWidth reader.lineBuffer, [] )
                |> Tuple.second
                |> List.reverse
            , { reader
                | lineBuffer = last
                , cursor = reader.cursor + Bytes.Encode.getStringWidth chunk |> clamp reader.start reader.end
              }
            )
