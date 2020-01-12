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
read : String -> Readline -> ( List String, Readline )
read chunk reader =
    case reader.lineBuffer ++ chunk |> String.lines |> List.reverse of
        -- this is impossible, string.split/string.lines never return an empty list
        [] ->
            ( [], reader )

        last :: rlines ->
            ( List.reverse rlines
            , { reader
                | lineBuffer = last
                , cursor = reader.cursor + String.length chunk |> clamp reader.start reader.end
              }
            )
