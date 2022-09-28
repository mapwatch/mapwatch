module SpeechTest exposing (..)

import Array
import Dict exposing (Dict)
import Expect
import Mapwatch.Datamine as Datamine exposing (Datamine, WorldArea, langIndexEmpty)
import Mapwatch.Instance as Instance exposing (Address, Instance)
import Mapwatch.MapRun as MapRun exposing (MapRun)
import Mapwatch.RawMapRun as RawMapRun exposing (RawMapRun)
import Mapwatch.Visit as Visit exposing (Visit)
import Settings exposing (Settings)
import Speech exposing (Speech)
import Test exposing (..)
import Time exposing (Posix)


emptyAddr : Address
emptyAddr =
    { zone = "nowhere", addr = "127.0.0.1:6112", worldArea = Nothing }


emptyInstance : Instance
emptyInstance =
    Instance.Instance emptyAddr


emptyWorldArea : WorldArea
emptyWorldArea =
    { id = "fake-world-area"
    , isTown = False
    , isHideout = False
    , isMapArea = True
    , isUniqueMapArea = False
    , isVaalArea = False
    , isLabTrial = False
    , isLabyrinth = False
    , isAbyssalDepths = False
    , itemVisualId = Nothing
    , poedbMapIcon = Nothing
    , atlasRegion = Nothing
    , tiers = Nothing
    }


hideoutWorldArea : WorldArea
hideoutWorldArea =
    { emptyWorldArea | id = "hideout-world-area", isTown = True, isHideout = True, isMapArea = False }


hideoutInstance : Instance
hideoutInstance =
    Instance.Instance { emptyAddr | worldArea = Just hideoutWorldArea }


emptySettings : Settings
emptySettings =
    let
        s =
            Settings.empty
    in
    { s | volume = 100 }


emptyRaw : RawMapRun
emptyRaw =
    { address = emptyAddr
    , startedAt = Time.millisToPosix 0
    , portals = 0
    , deaths = 0
    , npcSays = Dict.empty
    , visits = []
    , isAbandoned = False
    , positionStart = 69
    , positionEnd = 420
    , rituals = 0
    , level = Nothing
    }


emptyVisit : Visit
emptyVisit =
    { instance = emptyInstance
    , joinedAt = Time.millisToPosix 0
    , leftAt = Time.millisToPosix 0
    , positionStart = 6969
    , positionEnd = 42069
    , afk = []
    }


datamine : Datamine
datamine =
    Datamine.createDatamine_ Array.empty
        Dict.empty
        []
        []
        []
        Dict.empty


emptyRun =
    MapRun.fromRaw datamine emptyRaw


all : Test
all =
    describe "Speech"
        [ test "nothing" <|
            \_ ->
                Speech.joinInstance emptySettings True emptyInstance Nothing Nothing
                    |> Expect.equal Nothing
        , test "now starting" <|
            \_ ->
                Speech.joinInstance emptySettings True emptyInstance (Just emptyRaw) Nothing
                    |> Expect.equal (Just { text = "mapwatch now starting nowhere. ", volume = 1.0 })
        , test "not starting; nonempty visits" <|
            \_ ->
                Speech.joinInstance emptySettings True emptyInstance (Just { emptyRaw | visits = [ emptyVisit ] }) Nothing
                    |> Expect.equal Nothing
        , test "history not done" <|
            \_ ->
                Speech.joinInstance emptySettings False emptyInstance (Just emptyRaw) Nothing
                    |> Expect.equal Nothing
        , test "timer stopped" <|
            \_ ->
                Speech.joinInstance emptySettings True emptyInstance Nothing (Just emptyRun)
                    |> Expect.equal (Just { text = "mapwatch finished in 0 minutes 0 seconds for nowhere.  timer stopped. ", volume = 1.0 })
        , test "finished > now starting" <|
            \_ ->
                Speech.joinInstance emptySettings True emptyInstance (Just emptyRaw) (Just emptyRun)
                    |> Expect.equal (Just { text = "mapwatch finished in 0 minutes 0 seconds for nowhere.  now starting nowhere. ", volume = 1.0 })
        , test "ritual reminder" <|
            \_ ->
                Speech.joinInstance emptySettings True hideoutInstance (Just { emptyRaw | rituals = 3, visits = [ emptyVisit ] }) Nothing
                    |> Expect.equal (Just { text = "mapwatch reminder: did you spend your ritual tribute?", volume = 1.0 })
        , test "ritual reminder: only with enough rituals" <|
            \_ ->
                Speech.joinInstance emptySettings True hideoutInstance (Just { emptyRaw | rituals = 2, visits = [ emptyVisit ] }) Nothing
                    |> Expect.equal Nothing
        , test "ritual reminder: only when entering town" <|
            \_ ->
                Speech.joinInstance emptySettings True emptyInstance (Just { emptyRaw | rituals = 3, visits = [ emptyVisit ] }) Nothing
                    |> Expect.equal Nothing
        ]
