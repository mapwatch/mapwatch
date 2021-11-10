module View.Icon exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Encode as Json
import Mapwatch.Datamine as Datamine exposing (WorldArea)
import Mapwatch.MapRun exposing (MapRun)
import Mapwatch.MapRun.Conqueror as Conqueror
import Maybe.Extra
import Set
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
    case world.id of
        -- a few special cases
        "BetrayalSafeHouseFortress" -> Just jun
        "BetrayalSafeHouseAssassins" -> Just jun
        "BetrayalSafeHouseCaravan" -> Just jun
        "BetrayalSafeHouseLaboratory" -> Just jun
        "BetrayalMastermindFight" -> Just jun
        _ ->
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
    -- sideArea { name = "vaal big-icon", url = "Art/2DArt/UIImages/InGame/Metamorphosis/rewardsymbols/ChestUnopenedFragments.png?scale=1" }
    div [ class "vaal-minimap minimap" ] []


zana : Html msg
zana =
    -- sideArea { name = "zana", url = "Art/2DItems/Hideout/Interactive/CartographyDevice.png" }
    -- sideArea { name = "zana", url = "Art/2DArt/UIImages/InGame/Legion/LegionRewardMaps.png" }
    -- sideArea { name = "zana big-icon", url = "Art/2DArt/UIImages/InGame/Metamorphosis/rewardsymbols/ChestUnopenedMaps.png?scale=1" }
    div [ class "zana-minimap minimap" ] []


labTrialUrl : String
labTrialUrl =
    Datamine.imgCdn ++ "Art/2DArt/UIImages/InGame/Metamorphosis/rewardsymbols/ChestUnopenedLabyrinth.png?scale=1"


labTrial : Html msg
labTrial =
    -- sideArea { name = "trial", url = "Art/2DItems/Maps/Labyrinth.png" }
    -- sideArea { name = "trial big-icon", url = "Art/2DArt/UIImages/InGame/Metamorphosis/rewardsymbols/ChestUnopenedLabyrinth.png?scale=1" }
    -- sideArea { name = "trial", url = "Art/2DArt/UIImages/InGame/Legion/LegionRewardLabyrinth.png" }
    div [ class "lab-minimap minimap" ] []


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


sirus : Html msg
sirus =
    sideArea { name = "sirus", url = "Art/2DItems/Currency/Strongholds/WatchstoneIridescent.png?scale=1" }


uniqueMap : Html msg
uniqueMap =
    sideArea { name = "uniqueMap", url = "Art/2DItems/Maps/MaelstromofChaos.png?scale=1" }


blightedMap : Html msg
blightedMap =
    sideArea { name = "blightedMap", url = "Art/2DItems/Maps/Atlas2Maps/New/Beach.png?w=1&h=1&scale=1&mn=6&mt=1&mb=1" }


einhar : Html msg
einhar =
    -- sideArea { name = "einhar med-icon", url = "Art/2DArt/UIImages/InGame/Legion/LegionRewardBestiary.png?scale=1" }
    div [ class "bestiary-minimap minimap" ] []


alva : Html msg
alva =
    -- sideArea { name = "alva med-icon", url = "Art/2DItems/Effects/Portals/IncursionPortal.png" }
    div [ class "incursion-minimap minimap" ] []


niko : Html msg
niko =
    -- sideArea { name = "niko", url = "Art/2DArt/UIImages/InGame/Legion/LegionRewardFossils.png?scale=1" }
    -- sideArea { name = "niko big-icon", url = "Art/2DArt/UIImages/InGame/Metamorphosis/rewardsymbols/ChestUnopenedFossils.png?scale=1" }
    div [ class "delve-minimap minimap" ] []


jun : Html msg
jun =
    -- sideArea { name = "jun", url = "Art/2DArt/UIImages/InGame/Legion/LegionRewardScarabs.png?scale=1" }
    -- sideArea { name = "jun big-icon", url = "Art/2DArt/UIImages/InGame/Metamorphosis/rewardsymbols/ChestUnopenedScarabs.png?scale=1" }
    div [ class "betrayal-minimap minimap" ] []


cassia : Html msg
cassia =
    -- sideArea { name = "cassia", url = "Art/2DArt/UIImages/InGame/Blight/BuildButtonDefault.png?scale=1" }
    -- sideArea { name = "cassia", url = "Art/2DItems/Currency/Oils/GoldenOil.png?scale=1" }
    -- sideArea { name = "cassia big-icon", url = "Art/2DArt/UIImages/InGame/Metamorphosis/rewardsymbols/ChestUnopenedBlight.png?scale=1" }
    div [ class "blight-minimap minimap" ] []


tane : Html msg
tane =
    sideArea { name = "tane big-icon", url = "Art/2DArt/UIImages/InGame/Metamorphosis/rewardsymbols/ChestUnopenedMetamorph.png?scale=1" }


legion : Html msg
legion =
    -- sideArea { name = "legion big-icon", url = "Art/2DArt/UIImages/InGame/Metamorphosis/rewardsymbols/ChestUnopenedLegion.png?scale=1" }
    div [ class "legion-minimap minimap" ] []


delirium : Html msg
delirium =
    -- sideArea { name = "delirium big-icon", url = "Art/2DItems/Maps/DeliriumSplinter.png?scale=1" }
    div [ class "delirium-minimap minimap" ] []


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


karst : Html msg
karst =
    sideArea { name = "heist-npc med-icon", url = "Art/2DArt/UIImages/InGame/NPCWindow/Portraits/Karst.png?scale=1" }


niles : Html msg
niles =
    sideArea { name = "heist-npc med-icon", url = "Art/2DArt/UIImages/InGame/NPCWindow/Portraits/Niles.png?scale=1" }


huck : Html msg
huck =
    sideArea { name = "heist-npc med-icon", url = "Art/2DArt/UIImages/InGame/NPCWindow/Portraits/Huck.png?scale=1" }


tibbs : Html msg
tibbs =
    sideArea { name = "heist-npc med-icon", url = "Art/2DArt/UIImages/InGame/NPCWindow/Portraits/Tibbs.png?scale=1" }


nenet : Html msg
nenet =
    sideArea { name = "heist-npc med-icon", url = "Art/2DArt/UIImages/InGame/NPCWindow/Portraits/Nenet.png?scale=1" }


vinderi : Html msg
vinderi =
    sideArea { name = "heist-npc med-icon", url = "Art/2DArt/UIImages/InGame/NPCWindow/Portraits/Vinderi.png?scale=1" }


tortilla : Html msg
tortilla =
    sideArea { name = "heist-npc med-icon", url = "Art/2DArt/UIImages/InGame/NPCWindow/Portraits/Tullina.png?scale=1" }


gianna : Html msg
gianna =
    sideArea { name = "heist-npc med-icon", url = "Art/2DArt/UIImages/InGame/NPCWindow/Portraits/Gianna.png?scale=1" }


isla : Html msg
isla =
    sideArea { name = "heist-npc med-icon", url = "Art/2DArt/UIImages/InGame/NPCWindow/Portraits/Isla.png?scale=1" }


adiyah : Html msg
adiyah =
    sideArea { name = "heist-npc med-icon", url = "Art/2DArt/UIImages/InGame/NPCWindow/Portraits/Adiyah.png?scale=1" }


kurai : Html msg
kurai =
    sideArea { name = "heist-npc med-icon", url = "Art/2DArt/UIImages/InGame/NPCWindow/Portraits/Kura.png?scale=1" }


grandHeistGeneric : Html msg
grandHeistGeneric =
    sideArea { name = "med-icon", url = "Art/2DItems/Currency/Heist/BlueprintApproved.png?scale=1" }


heistContractGeneric : Html msg
heistContractGeneric =
    sideArea { name = "med-icon", url = "Art/2DItems/Currency/Heist/ContractItem.png?scale=1" }


divCard : Html msg
divCard =
    -- not a side-area icon, this is for the divcard-drops under the timer
    img [ class "divcard side-icon", src "https://web.poecdn.com/image/Art/2DItems/Divination/InventoryIcon.png?scale=1" ] []


envoy : Html msg
envoy =
    -- sideArea { name = "envoy med-icon", url = "Art/2DItems/Effects/Portals/MavenPortalEffect.png?scale=1" }
    sideArea { name = "envoy med-icon", url = "Art/2DItems/Currency/AtlasRadiusTier4.png?scale=1" }


maven : Html msg
maven =
    -- sideArea { name = "maven med-icon", url = "Art/2DItems/Effects/Portals/MavenPortalEffect.png?scale=1" }
    sideArea { name = "maven med-icon", url = "Art/2DItems/Currency/AtlasRadiusTier4.png?scale=1" }


harvest : Html msg
harvest =
    -- sideArea { name = "harvest big-icon", url = "Art/2DItems/Effects/Portals/HarvestPortal.png?scale=1" }
    -- sideArea { name = "harvest big-icon", url = "Art/2DItems/Maps/OshabiMap.png?scale=1" }
    div [ class "harvest-minimap minimap" ] []


trialmaster : Html msg
trialmaster =
    div [ class "ultimatum-minimap minimap" ] []


gwennen : Html msg
gwennen =
    -- sideArea { name = "envoy med-icon", url = "Art/2DItems/Effects/Portals/MavenPortalEffect.png?scale=1" }
    -- sideArea { name = "gwennen expedition med-icon", url = "Art/2DArt/UIImages/InGame/Expedition/DruidsOfTheWebHeraldryIcon.png?scale=1" }
    div [ class "expedition-minimap minimap" ] []


tujen : Html msg
tujen =
    -- sideArea { name = "envoy med-icon", url = "Art/2DItems/Effects/Portals/MavenPortalEffect.png?scale=1" }
    -- sideArea { name = "tujen expedition med-icon", url = "Art/2DArt/UIImages/InGame/Expedition/BlackSwordMercenariesHeraldryIcon.png?scale=1" }
    div [ class "expedition-minimap minimap" ] []


rog : Html msg
rog =
    -- sideArea { name = "envoy med-icon", url = "Art/2DItems/Effects/Portals/MavenPortalEffect.png?scale=1" }
    -- sideArea { name = "rog expedition med-icon", url = "Art/2DArt/UIImages/InGame/Expedition/OrderOfTheChaliceHeraldryIcon.png?scale=1" }
    div [ class "expedition-minimap minimap" ] []


dannig : Html msg
dannig =
    -- sideArea { name = "envoy med-icon", url = "Art/2DItems/Effects/Portals/MavenPortalEffect.png?scale=1" }
    -- sideArea { name = "dannig expedition med-icon", url = "Art/2DArt/UIImages/InGame/Expedition/KnightsOfTheWolfHeraldryIcon.png?scale=1" }
    div [ class "expedition-minimap minimap" ] []
