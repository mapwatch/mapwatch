module View.Icon exposing (abyss, fa, fas, fasPulse, labTrial, map, mapOrBlank, vaal, zana)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Json.Encode as Json
import Mapwatch.Datamine as Datamine exposing (WorldArea)
import Regex


fa : String -> String -> Html msg
fa icongroup icon =
    -- https://fontawesome.com/icons/
    span [ class <| icongroup ++ " fa-" ++ icon, property "aria-hidden" (Json.bool True) ] []


fas =
    fa "fas"


fasPulse =
    fa "fa-spin fa-pulse fas"


map : Maybe WorldArea -> Maybe (Html msg)
map =
    Maybe.andThen
        (\world ->
            world
                |> Datamine.imgSrc
                |> Maybe.map (\src_ -> img [ class <| "map-icon map-icon-" ++ world.id, src src_ ] [])
        )


mapOrBlank : Maybe WorldArea -> Html msg
mapOrBlank =
    map >> Maybe.withDefault (span [] [])


sideArea : { name : String, url : String } -> Html msg
sideArea { name, url } =
    img [ class ("side-icon side-icon-" ++ name), src <| Datamine.imgCdn ++ url ] []


vaal : Html msg
vaal =
    -- sideArea { name = "vaal", url = "Art/2DItems/Maps/Vaal01.png" }
    sideArea { name = "vaal", url = "Art/2DArt/UIImages/InGame/Legion/LegionRewardFragments.png" }


zana : Html msg
zana =
    -- sideArea { name = "zana", url = "Art/2DItems/Hideout/Interactive/CartographyDevice.png" }
    sideArea { name = "zana", url = "Art/2DArt/UIImages/InGame/Legion/LegionRewardMaps.png" }


labTrial : Html msg
labTrial =
    -- sideArea { name = "trial", url = "Art/2DItems/Maps/Labyrinth.png" }
    sideArea { name = "trial", url = "Art/2DArt/UIImages/InGame/Legion/LegionRewardLabyrinth.png" }


abyss : Html msg
abyss =
    sideArea { name = "abyss", url = "Art/2DArt/UIImages/InGame/Legion/LegionRewardAbyss.png" }
