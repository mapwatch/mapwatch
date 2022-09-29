## global-ish keys
title = PoE Mapwatch
not-found = 404
processed-bytes = Processed {$bytes} in {NUMBER($dur)}s

## top navbar
nav-header = Mapwatch
nav-subheader = - automatically time your Path of Exile map clears
nav-timer = Timer
nav-history = History
nav-maps = Maps
nav-encounters = Encounters
nav-changelog = Changelog
nav-settings = Settings

## homepage; https://mapwatch.erosson.org/ 
setup-desc-1 = Give me your <a data-l10n-name="link">Path of Exile</a> <code>Client.txt</code> file, and I'll give you some statistics about your recent mapping activity.
setup-desc-2-www = Then, <a data-l10n-name="link">if you're using the Mapwatch app</a>, leave me open while you play - I'll keep watching, no need to upload again.
setup-desc-2-electron = Then, leave me open while you play - I'll keep watching, no need to upload again.
setup-example = Run an example now!

setup-form-max-size = Analyze only the last <input data-l10n-name="input" /> MB of history
setup-form-file-label = Client.txt:
setup-form-file-hint = Hint - the file I need is usually in one of these places:
setup-form-file-hint-path-1 = C:\Program Files (x86)\Grinding Gear Games\Path of Exile\logs\Client.txt
setup-form-file-hint-path-2 = C:\Steam\steamapps\common\Path of Exile\logs\Client.txt

setup-form-nativefs-button = Choose File
setup-form-nativefs-hint-1 = Hint - <a data-l10n-name="link">read this first!</a> This <code>nativefs</code> version of Mapwatch needs some extra work.
setup-form-nativefs-hint-2 = If you've set things up properly, the file I need is here, near your item filters: <code>C:\Users\%USERNAME%\Documents\My Games\Path of Exile\mapwatch.erosson.org---Client.txt</code>
setup-form-nativefs-hint-3 = Alternately, <a data-l10n-name="link-www">use the original web version of Mapwatch</a> (with no updates while you play), or <a data-l10n-name="link-download">download Mapwatch</a>.

setup-download-header = New: <a data-l10n-name="link">download Mapwatch</a> to see your maps updated while you play!
setup-download-subheader = (Sadly, updates while you play will soon be <a data-l10n-name="link">unavailable</a> in all web browsers.)

setup-speech-volume = Speech volume:

## top searchbar
search-hover =
    .title =
        To see searchable text for a map-run, hover over its region on the history screen.
        Search accepts regular expressions.
search-input =
    .placeholder = area name

search-goal-none = No time goal
search-goal-best-today = Goal: today's best
search-goal-best-session = Goal: session best
search-goal-best-ever = Goal: all-time best
search-goal-mean-today = Goal: today's average
search-goal-mean-session = Goal: session average
search-goal-mean-ever = Goal: all-time average
search-goal-exactly = Goal: exactly...
search-goal-exactly-input = 
    .placeholder = "5:00" or "300" or "5m 0s" 

## https://mapwatch.erosson.org/#/settings
settings-reset = Analyze another Client.txt log file
settings-source = Mapwatch is open source! <a data-l10n-name="link">View the source code</a>.
settings-privacy = Mapwatch Privacy Policy

## https://mapwatch.erosson.org/#/changelog
changelog-source = Mapwatch is open source! <a data-l10n-name="link">View the source code</a>.
changelog-report = Is something broken? Contact the developer: <a data-l10n-name="link-keybase">Keybase chat</a>, <a data-l10n-name="link-issue">GitHub issue</a>, or <a data-l10n-name="link-reddit">Reddit</a>.
changelog-app = Changes listed below affect both the Mapwatch website and the Mapwatch app. <a data-l10n-name="link">The app sometimes has additional changes, listed on its releases page</a>.

notify-rss = RSS notifications
notify-email = Email notifications

## https://mapwatch.erosson.org/#/timer
timer-in = Mapping in:
timer-map-wiki = wiki
timer-drops = {NUMBER($divs)} divination cards
timer-last-entered = Last entered:
timer-done-today = Maps done today:
timer-done-this-session = Maps done this session:
timer-hide-earlier = Hide earlier maps
timer-hide-league = Hide pre-{$league} maps
timer-unhide = Unhide all
timer-snapshot = Snapshot history
timer-history = History
timer-overlay = Overlay
timer-not-mapping = Not mapping

## https://mapwatch.erosson.org/#/encounters
encounters-desc =
    .title = I try not to screw up these numbers or otherwise mislead people, but if it keeps happening I'm going to just delete this damn page
encounters-desc-header = Do not blindly trust Mapwatch
encounters-desc-1 = Sometimes Mapwatch is misleading or just plain wrong. Before using this page as evidence for your Angry Reddit Thread about spawn rates, you should double-check Mapwatch's numbers, and think carefully about your conclusions.
encounters-desc-2 = It is <i>very unlikely</i> that you've found a Path of Exile bug.
encounters-table-map-name = Map encounters
encounters-table-map-rate = % of {NUMBER($n)} maps
encounters-table-endgame-name = Endgame area encounters
encounters-table-endgame-rate = % of {NUMBER($n)} endgame areas
encounters-table-trialmaster-name = Trialmaster encounters
encounters-table-trialmaster-rate = % of {NUMBER($n)} trialmasters
encounters-table-trialmaster-wins-name = Trialmaster wins + bosses
encounters-table-trialmaster-wins-rate = % of {NUMBER($n)} trialmaster wins + bosses
encounters-count = ×{NUMBER($n)}

bosses-atziri = Atziri, Queen of the Vaal: Apex of Sacrifice
bosses-uber-atziri = The Alluring Abyss (Uber Atziri) (Witnessed)
bosses-uber-elder = The Elder in the Shaper's Realm (Witnessed)
bosses-uber-uber-elder = The Elder in the Shaper's Realm (Uber) (Witnessed)
bosses-venarius = High Templar Venarius
bosses-uber-venarius = High Templar Venarius (Uber)
bosses-maven = {npc-maven}
bosses-uber-maven = {npc-maven} (Uber)
bosses-sirus = {npc-sirus}
bosses-uber-sirus = {npc-sirus} (Uber)
bosses-eater = {npc-eater}
bosses-uber-eater = {npc-eater} (Uber)
bosses-exarch = {npc-exarch}
bosses-uber-exarch = {npc-exarch} (Uber)
bosses-conquerors = Lesser Conquerors of the Atlas
bosses-baran = {npc-baran}
bosses-veritania = {npc-veritania}
bosses-alhezmin = {npc-alhezmin}
bosses-drox = {npc-drox}
bosses-hunger = {npc-hunger}
bosses-blackstar = {npc-blackstar}
bosses-shaper = The Shaper
bosses-elder = The Elder (Witnessed)
bosses-shaper-guardians = Shaper Guardians
bosses-shaper-chimera = Guardian of the Chimera
bosses-shaper-hydra = Guardian of the Hydra
bosses-shaper-minotaur = Guardian of the Minotaur
bosses-shaper-phoenix = Guardian of the Phoenix

## https://mapwatch.erosson.org/#/encounters > encounter types
encounter-abyssal = Abyssal Depths
encounter-vaal = Vaal side areas
encounter-trial = ({NUMBER($n)}/6) Labyrinth Trials
encounter-conquerors = Conqueror fights
    .title = excluding Sirus
encounter-zana = Zana
encounter-einhar = Einhar
encounter-alva = Alva
encounter-niko = Niko
encounter-jun = Jun
encounter-cassia = Cassia
encounter-delirium = Delirium
encounter-oshabi = Oshabi <b>*</b>
encounter-oshabi-warn = * Beware: Mapwatch cannot accurately track Harvests. <a data-l10n-name="link">Your true Harvest rate is higher.</a>
encounter-heart-grove = Heart of the Grove
encounter-envoy = The Envoy
encounter-sirus-invasions = Sirus invasions
encounter-maven = The Maven
encounter-trialmaster = The Trialmaster
encounter-gwennen = Gwennen, the Gambler
encounter-tujen = Tujen, the Haggler
encounter-rog = Rog, the Dealer
encounter-dannig = Dannig, Warrior Skald
encounter-grand-heist = Grand Heists
encounter-heist-contract = Heist Contracts
encounter-normal-maps = Maps (non-unique, non-blighted)
encounter-lab = The Labyrinth
encounter-unique-maps = Unique Maps
encounter-blighted-maps = Blighted Maps
encounter-maven-hub = The Maven's Crucible
encounter-sirus = Eye of the Storm (Sirus)
encounter-trialmasters-won = Trialmasters won
encounter-trialmasters-lost = Trialmasters lost
encounter-trialmasters-retreated = Trialmasters retreated
encounter-trialmasters-incomplete = Trialmasters incomplete
encounter-trialmaster-boss = Trialmaster boss fights *
encounter-trialmaster-boss-warn = <a data-l10n-name="link">Trialmaster boss fight rate</a> depends on map level, which Mapwatch cannot track.
encounter-ritual = Ritual

## https://mapwatch.erosson.org/#/maps
maps-th-name = Name
maps-th-region = Region
maps-th-tier = Tier
maps-th-mean = Average
maps-th-portals = Portals
maps-th-deaths = Deaths
maps-th-count = # Runs
maps-th-best = Best

maps-td-tier = (T{NUMBER($n)})
maps-td-mean = {$time} per map
maps-td-portals = {NUMBER($n) ->
    [one] {NUMBER($n)} portal
    *[other] {NUMBER($n)} portals
}
maps-td-deaths = {NUMBER($n) ->
    [0] {""}
    [zero] {""}
    [one] {NUMBER($n)} death
    *[other] {NUMBER($n)} deaths
}
maps-td-count = {NUMBER($n) ->
    [one] ×{NUMBER($n)} run
    *[other] ×{NUMBER($n)} runs
}

## https://mapwatch.erosson.org/#/history
history-export = Export as:
history-export-tsv = TSV spreadsheet
history-export-google = Google Sheets (BETA)
history-page-first = First
history-page-prev = Prev
history-page-next = Next
history-page-last = Last
history-page-count = {NUMBER($first)} - {NUMBER($last)} of {NUMBER($count)}

history-dur-map = {$dur} in map
history-dur-town = {$dur} in town
history-dur-sides = {$dur} in sides
history-dur-portals = {NUMBER($n)} {$n ->
    [one] portal
    *[other] portals
}
history-dur-deaths = {NUMBER($n) ->
    [0] {""}
    [zero] {""}
    [one] {NUMBER($n)} death
    *[other] {NUMBER($n)} deaths
}
history-dur-town-pct = {NUMBER($pct)}% in town
history-npc-side-area =
    .title = Encountered this NPC in a side area
history-summary-today = Today
history-summary-alltime = All-time
history-summary-session = This session
history-summary-count = {NUMBER($n)} {$n ->
    [one] map
    *[other] maps
} completed
history-summary-th-mean = Average time per map
history-summary-th-total = Total time
history-searchable =
    .title = 
        Searchable text for this run:

        {$searchable}
history-run-abandoned = ???
    .title =
        Map run abandoned - you went offline without returning to town first!
        
        Sadly, when you go offline without returning to town, Mapwatch cannot know how long you spent in the map. Times shown here will be wrong.
        
        See also https://github.com/mapwatch/mapwatch/issues/66
history-afk-mode = AFK mode:
history-ritual = Ritual ({NUMBER($n)})
history-heart-of-the-grove = Heart of the Grove

## https://mapwatch.erosson.org/#/history/tsv > encounter types
npc-einhar = Einhar, Beastmaster
npc-alva = Alva, Master Explorer
npc-niko = Niko, Master of the Depths
npc-jun = Jun, Veiled Master
npc-cassia = Sister Cassia
npc-delirium = Delirium Mirror
npc-legion-general = Legion General
npc-karst = Karst, the Lockpick
npc-niles = Niles, the Interrogator
npc-huck = Huck, the Soldier
npc-tibbs = Tibbs, the Giant
npc-nenet = Nenet, the Scout
npc-vinderi = Vinderi, the Dismantler
npc-tullina = Tullina, the Catburglar
# https://www.reddit.com/r/pathofexile/comments/iwbvt2/got_it_good/
npc-tortilla = {$name}, the Catburglar
npc-gianna = Gianna, the Master of Disguise
npc-isla = Isla, the Engineer
npc-envoy = The Envoy
npc-maven = The Maven
npc-oshabi = Oshabi
npc-sirus = Sirus, Awakener of Worlds
npc-gwennen = Gwennen, the Gambler
npc-tujen = Tujen, the Haggler
npc-rog = Rog, the Dealer
npc-dannig = Dannig, Warrior Skald
npc-baran = Baran, the Crusader
npc-veritania = Veritania, the Redeemer
npc-alhezmin = Al-Hezmin, the Hunter
npc-drox = Drox, the Warlord
npc-conqueror-taunt = : Taunt {NUMBER($n)}
npc-conqueror-fight = : Fight

npc-trialmaster-boss = Trialmaster boss fight: {$result}
npc-trialmaster = The Trialmaster: {$result} ({NUMBER($n)})

npc-blackstar = The Black Star
npc-exarch = The Searing Exarch
npc-eater = The Eater of Worlds
npc-hunger = The Infinite Hunger

side-area-zana = Zana
side-area-vaal = Vaal side area
side-area-trial = Labyrinth trial

## https://mapwatch.erosson.org/#/history/tsv
history-tsv-header = Copy and paste the <b>Tab-Separated Values</b> below into your favorite spreadsheet application.
history-tsv-history = History: 
history-tsv-maps = Maps: 
history-tsv-encounters = Encounters: 
