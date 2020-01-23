module Mapwatch.MapRun.ConquerorTest exposing (..)

import Expect
import Mapwatch.Instance as Instance exposing (Address)
import Mapwatch.MapRun.Conqueror as Conqueror exposing (emptyState)
import Set exposing (Set)
import Test exposing (..)


emptyAddr : Address
emptyAddr =
    { zone = "nowhere", addr = "127.0.0.1:6112", worldArea = Nothing }


sirusAddr : Address
sirusAddr =
    { emptyAddr
        | zone = "siruslol"
        , worldArea =
            Just
                { id = "AtlasExilesBoss5"
                , isTown = False
                , isHideout = False
                , isMapArea = False
                , isUniqueMapArea = False
                , isVaalArea = False
                , isLabTrial = False
                , isAbyssalDepths = False
                , itemVisualId = Nothing
                , atlasRegion = Nothing
                , tiers = Nothing
                }
    }


emptyRun =
    { address = emptyAddr, conqueror = Nothing }


encounterState : Conqueror.Encounter -> Conqueror.State1
encounterState e =
    Conqueror.State1 (Just e) Nothing Set.empty


all : Test
all =
    describe "Mapwatch.MapRun.Conqueror"
        [ test "emptyList" <|
            \_ ->
                Conqueror.createState []
                    |> Expect.equal emptyState
        , test "emptyConq" <|
            \_ ->
                Conqueror.createState [ emptyRun ]
                    |> Expect.equal emptyState
        , test "taunt" <|
            \_ ->
                Conqueror.createState [ { emptyRun | conqueror = Just ( Conqueror.Baran, Conqueror.Taunt 1 ) } ]
                    |> Expect.equal { emptyState | baran = encounterState (Conqueror.Taunt 1) }
        , test "4" <|
            \_ ->
                Conqueror.createState
                    [ { emptyRun | conqueror = Just ( Conqueror.Baran, Conqueror.Taunt 1 ) }
                    , { emptyRun | conqueror = Just ( Conqueror.Veritania, Conqueror.Taunt 2 ) }
                    , { emptyRun | conqueror = Just ( Conqueror.AlHezmin, Conqueror.Taunt 3 ) }
                    , { emptyRun | conqueror = Just ( Conqueror.Drox, Conqueror.Fight ) }
                    ]
                    |> Expect.equal
                        { emptyState
                            | baran = encounterState (Conqueror.Taunt 1)
                            , veritania = encounterState (Conqueror.Taunt 2)
                            , alHezmin = encounterState (Conqueror.Taunt 3)
                            , drox = encounterState Conqueror.Fight
                        }
        , test "taunt x2" <|
            \_ ->
                Conqueror.createState
                    [ { emptyRun | conqueror = Just ( Conqueror.Baran, Conqueror.Taunt 2 ) }
                    , { emptyRun | conqueror = Just ( Conqueror.Baran, Conqueror.Taunt 3 ) }
                    , { emptyRun | conqueror = Just ( Conqueror.Baran, Conqueror.Taunt 1 ) }
                    ]
                    |> Expect.equal { emptyState | baran = encounterState (Conqueror.Taunt 2) }
        , test "sirus resets" <|
            \_ ->
                Conqueror.createState
                    [ { emptyRun | conqueror = Just ( Conqueror.Drox, Conqueror.Taunt 3 ) }
                    , { emptyRun | address = sirusAddr }
                    , { emptyRun | conqueror = Just ( Conqueror.Baran, Conqueror.Taunt 2 ) }
                    ]
                    |> Expect.equal { emptyState | drox = encounterState (Conqueror.Taunt 3) }
        ]
