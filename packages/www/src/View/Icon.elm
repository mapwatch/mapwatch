module View.Icon exposing (..)

import Html as H exposing (..)
import Html.Attributes as A exposing (..)
import Html.Events as E exposing (..)
import Json.Encode as Json
import Mapwatch.Datamine as Datamine exposing (Datamine, WorldArea)
import Mapwatch.MapRun as MapRun exposing (MapRun)
import Mapwatch.MapRun.Conqueror as Conqueror
import Maybe.Extra
import Regex
import Set exposing (Set)
import View.Icon.Svg


type alias MapIconArgs a =
    Datamine.MapIconArgs a


fa : String -> String -> Html msg
fa icongroup icon =
    -- https://fontawesome.com/icons/
    span [ class <| icongroup ++ " fa-" ++ icon, property "aria-hidden" (Json.bool True) ] []


fas =
    fa "fas"


fab =
    fa "fab"


fasPulse =
    fa "fa-spin fa-pulse fas"


runMap : MapRun -> Maybe (Html msg)
runMap run =
    map run run.address.worldArea


justMap : MapIconArgs a -> WorldArea -> Maybe (Html msg)
justMap args world =
    world
        |> Datamine.imgSrc args
        |> Maybe.map (\src_ -> img [ class <| "map-icon map-icon-" ++ world.id, src src_ ] [])


map : MapIconArgs a -> Maybe WorldArea -> Maybe (Html msg)
map args =
    Maybe.andThen (justMap args)


mapOrBlank : MapIconArgs a -> Maybe WorldArea -> Html msg
mapOrBlank args =
    map args >> Maybe.withDefault (span [] [])


sideArea : { name : String, url : String } -> Html msg
sideArea { name, url } =
    img [ class ("side-icon side-icon-" ++ name), src <| Datamine.imgCdn ++ url ] []



-- old hardcoded map list, useful when searching for icon art:
-- https://github.com/mapwatch/mapwatch/blob/8daf3a6c1562b707f040912a8e90206832d71c03/packages/lib/src/Mapwatch/MapList.elm


vaal : Html msg
vaal =
    -- sideArea { name = "vaal", url = "Art/2DItems/Maps/Vaal01.png" }
    -- sideArea { name = "vaal", url = "Art/2DArt/UIImages/InGame/Legion/LegionRewardFragments.png" }
    sideArea { name = "vaal big-icon", url = "Art/2DArt/UIImages/InGame/Metamorphosis/rewardsymbols/ChestUnopenedFragments.png?scale=1" }


zana : Html msg
zana =
    -- sideArea { name = "zana", url = "Art/2DItems/Hideout/Interactive/CartographyDevice.png" }
    -- sideArea { name = "zana", url = "Art/2DArt/UIImages/InGame/Legion/LegionRewardMaps.png" }
    sideArea { name = "zana big-icon", url = "Art/2DArt/UIImages/InGame/Metamorphosis/rewardsymbols/ChestUnopenedMaps.png?scale=1" }


labTrial : Html msg
labTrial =
    -- sideArea { name = "trial", url = "Art/2DItems/Maps/Labyrinth.png" }
    -- sideArea { name = "trial", url = "Art/2DArt/UIImages/InGame/Legion/LegionRewardLabyrinth.png" }
    sideArea { name = "trial big-icon", url = "Art/2DArt/UIImages/InGame/Metamorphosis/rewardsymbols/ChestUnopenedLabyrinth.png?scale=1" }


abyss : Html msg
abyss =
    -- sideArea { name = "abyss", url = "Art/2DArt/UIImages/InGame/Legion/LegionRewardAbyss.png" }
    sideArea { name = "abyss big-icon", url = "Art/2DArt/UIImages/InGame/Metamorphosis/rewardsymbols/ChestUnopenedAbyss.png?scale=1" }


baran : Html msg
baran =
    sideArea { name = "baran", url = "Art/2DItems/Currency/Strongholds/WatchstoneRed.png?scale=1" }


veritania : Html msg
veritania =
    sideArea { name = "veritania", url = "Art/2DItems/Currency/Strongholds/WatchstoneBlue.png?scale=1" }


alHezmin : Html msg
alHezmin =
    sideArea { name = "alHezmin", url = "Art/2DItems/Currency/Strongholds/WatchstoneGreen.png?scale=1" }


drox : Html msg
drox =
    sideArea { name = "drox", url = "Art/2DItems/Currency/Strongholds/WatchstoneYellow.png?scale=1" }


einhar : Html msg
einhar =
    sideArea { name = "einhar med-icon", url = "Art/2DArt/UIImages/InGame/Legion/LegionRewardBestiary.png?scale=1" }


alva : Html msg
alva =
    sideArea { name = "alva med-icon", url = "Art/2DItems/Effects/Portals/IncursionPortal.png" }


niko : Html msg
niko =
    -- sideArea { name = "niko", url = "Art/2DArt/UIImages/InGame/Legion/LegionRewardFossils.png?scale=1" }
    sideArea { name = "niko big-icon", url = "Art/2DArt/UIImages/InGame/Metamorphosis/rewardsymbols/ChestUnopenedFossils.png?scale=1" }


jun : Html msg
jun =
    -- sideArea { name = "jun", url = "Art/2DArt/UIImages/InGame/Legion/LegionRewardScarabs.png?scale=1" }
    sideArea { name = "jun big-icon", url = "Art/2DArt/UIImages/InGame/Metamorphosis/rewardsymbols/ChestUnopenedScarabs.png?scale=1" }


cassia : Html msg
cassia =
    -- sideArea { name = "cassia", url = "Art/2DArt/UIImages/InGame/Blight/BuildButtonDefault.png?scale=1" }
    -- sideArea { name = "cassia", url = "Art/2DItems/Currency/Oils/GoldenOil.png?scale=1" }
    sideArea { name = "cassia big-icon", url = "Art/2DArt/UIImages/InGame/Metamorphosis/rewardsymbols/ChestUnopenedBlight.png?scale=1" }


tane : Html msg
tane =
    sideArea { name = "tane big-icon", url = "Art/2DArt/UIImages/InGame/Metamorphosis/rewardsymbols/ChestUnopenedMetamorph.png?scale=1" }


delirium : Html msg
delirium =
    sideArea { name = "delirium big-icon", url = "Art/2DItems/Maps/DeliriumSplinter.png?scale=1" }


region : Maybe WorldArea -> Html msg
region w =
    w
        |> Maybe.andThen .atlasRegion
        |> Maybe.Extra.unwrap View.Icon.Svg.empty
            (\r -> View.Icon.Svg.applyRegionName r (Just View.Icon.Svg.Selected) View.Icon.Svg.empty)
        |> View.Icon.Svg.regions


conquerorRegions : Conqueror.Id -> Conqueror.State1 -> Html msg
conquerorRegions id state =
    let
        conq : View.Icon.Svg.RegionStatus
        conq =
            case id of
                Conqueror.Baran ->
                    View.Icon.Svg.Baran

                Conqueror.Veritania ->
                    View.Icon.Svg.Veritania

                Conqueror.AlHezmin ->
                    View.Icon.Svg.AlHezmin

                Conqueror.Drox ->
                    View.Icon.Svg.Drox

        empty : View.Icon.Svg.Regions
        empty =
            View.Icon.Svg.init (Just View.Icon.Svg.Unsighted)

        sightings : View.Icon.Svg.Regions
        sightings =
            Set.foldl (\r -> View.Icon.Svg.applyRegionName r (Just View.Icon.Svg.Sighted)) empty state.sightings

        regions : View.Icon.Svg.Regions
        regions =
            sightings
                |> (case state.region of
                        Nothing ->
                            identity

                        Just r ->
                            View.Icon.Svg.applyRegionName r (Just conq)
                   )
    in
    View.Icon.Svg.regions regions
