module MapwatchTest exposing (..)

import Expect
import Fixture exposing (datamine)
import Mapwatch exposing (Model)
import Settings exposing (Settings)
import Test exposing (..)


all : Test
all =
    describe "Readline" <|
        [ test "parse empty" <|
            \_ ->
                """
                """
                    |> Mapwatch.fromLogSlice Nothing datamine Settings.empty 0
                    |> .runs
                    |> Expect.equal []
        , test "parse simple" <|
            \_ ->
                """
                2021/05/06 03:17:38] : You have entered Residence.
                2021/05/06 03:23:39] Connecting to instance server at 999.999.999.1:6112
                2021/05/06 03:23:39] : You have entered Stately Hideout.
                2021/05/06 03:24:08] Connecting to instance server at 999.999.999.0:6112
                2021/05/06 03:24:09] : You have entered Residence.
                2021/05/06 03:27:30] Connecting to instance server at 999.999.999.1:6112
                2021/05/06 03:27:31] : You have entered Stately Hideout.
                2021/05/06 03:32:49] Connecting to instance server at 999.999.999.2:6112
                2021/05/06 03:32:51] : You have entered Port.
                """
                    |> Mapwatch.fromLogSlice Nothing datamine Settings.empty 0
                    |> .runs
                    |> Expect.equal []
        ]
