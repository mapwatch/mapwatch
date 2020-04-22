# i18n with https://projectfluent.org/
# the .properties file extension gives my editor decent syntax highlighting

title = Mapwatch
subtitle = - automatically time your Path of Exile map clears

-league = Delirium

### Navigation ###

nav-timer = Timer
nav-history = History
nav-maps = Maps
nav-encounters = Encounters
nav-changelog = Changelog
nav-settings = Settings

### Setup ###

setup-intro1 =
  Give me your
  <a target="_blank" href="https://www.pathofexile.com">
    Path of Exile</a>
  <code>Client.txt</code>
  file, and I'll give you some statistics about your recent mapping activity.

setup-electron-intro2 =
  Then, leave me open while you play - I'll keep watching, no need to upload again.

setup-www-download-intro2 =
  Then,
  <a href="https://github.com/mapwatch/mapwatch/releases/latest">
    if you're using the Mapwatch app</a>,
  leave me open while you play - I'll keep watching, no need to upload again.

setup-www-nodownload-intro2 =
  Then,
  <a target="_blank" href="https://chrome.google.com">
    if you're using Google Chrome</a>,
  leave me open while you play - I'll keep watching, no need to upload again.

setup-example = Run an example now!

setup-download-link =
  New:
  <b><a href="https://github.com/mapwatch/mapwatch/releases/latest">
    download Mapwatch</a></b>
  to see your maps updated while you play!

setup-download-why =
  (Sadly, updates while you play will soon be
  <a target="_blank" href="https://github.com/mapwatch/mapwatch/blob/master/WATCHING.md">
    unavailable</a>
  in all web browsers.)

setup-size-pre = Analyze only the last
setup-size-post = MB of history
setup-filepicker = Client.txt:

setup-filepicker-help =
  Hint - the file I need is usually in one of these places:<br>
  <code>C:\Program Files (x86)\Grinding Gear Games\Path of Exile\logs\Client.txt</code><br>
  <code>C:\Steam\steamapps\common\Path of Exile\logs\Client.txt</code>

setup-filepicker-native-button =
  Choose File

setup-filepicker-native-help1 =
  Hint -
  <a target="_blank" href="https://github.com/mapwatch/mapwatch/blob/master/WATCHING.md">
    read this first!</a>
  This <code>nativefs</code> version of Mapwatch needs some extra work.

setup-filepicker-native-help2 =
  If you've set things up properly, the file I need is here, near your item filters:<br>
  <code>C:\Users\%USERNAME%\Documents\My Games\Path of Exile\mapwatch.erosson.org---Client.txt</code>

setup-filepicker-native-help3 =
  Alternately,
  <a href="https://mapwatch.erosson.org">
    use the original web version of Mapwatch</a>
  (with no updates while you play), or
  <a target="_blank" href="https://github.com/mapwatch/mapwatch/releases/latest">
    download Mapwatch</a>.

setup-badbrowser =
  Warning: we don't support your web browser. If you have trouble, try
  <a target="_blank" href="https://www.google.com/chrome/">
    Chrome</a>.

### Changelog ###

changelog-opensource =
  Mapwatch is open source!
  <a target="_blank" href="https://www.github.com/mapwatch/mapwatch">
    View the source code.</a>

changelog-contactdev =
  Is something broken? Contact the developer:
  <a href="https://keybase.io/erosson/chat" target="_blank">
    Keybase chat</a>,
  <a href="https://github.com/mapwatch/mapwatch/issues/new" target="_blank">
    GitHub issue</a>, or
  <a href="https://www.reddit.com/message/compose/?to=kawaritai&subject=Mapwatch" target="_blank">
    Reddit</a>.

changelog-app =
  Changes listed below affect both the Mapwatch website and the Mapwatch app.
  <a href="https://github.com/mapwatch/mapwatch/releases" target="_blank">
    The app sometimes has additional changes, listed on its releases page.
  </a>

changelog-rss = RSS notifications
changelog-email = Email notifications

### Settings ###

settings-volume = Speech volume:
settings-reset = Analyze another Client.txt log file
settings-privacy = Mapwatch Privacy Policy
settings-debug = secret debugging tools

settings-locale-label = Language:
settings-locale-volunteer = Can you help translate Mapwatch?
settings-locale-entry-default = Default
settings-locale-entry-en-US = English (US)
settings-locale-entry-test = Test

### Timer ###

timer-currentmap = Mapping in:
timer-currentmap-none = Not mapping
timer-lastentered = Mapping in:
timer-donetoday = Maps done today:
timer-donesession = Maps done this session:
timer-link-history = History
timer-link-overlay = Overlay

timer-filter-earlier = Hide earlier maps
timer-filter-snapshot = Snapshot history

### History ###

history-page-first = First
history-page-prev = Prev
history-page-next = Next
history-page-last = Last
history-page-count = {$pageStart} - {$pageEnd} of {$total}

history-export-onlytsv = Export as TSV spreadsheet
history-export-header = Export as:
history-export-tsv = TSV spreadsheet
history-export-gsheets = Google Sheets (BETA)

history-summary-session = This session
history-summary-today = Today
history-summary-alltime = All-time
history-summary-completed = {$count ->
  [one] {$count} map completed
  *[other] {$count} maps completed
}
history-summary-meandur = Average time per map
history-summary-totaldur = Total time

# https://projectfluent.org/fluent/guide/functions.html#datetime
history-row-date = {DATETIME($date,
    hour12: 0,
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "numeric",
  )}
history-row-region =
  .title =
    Searchable text for this run:

    {$body}
history-row-duration-map = {$duration} in map
history-row-duration-town = {$duration} in town
history-row-duration-sides = {$duration} in sides
history-row-portals = {$count ->
  [one] {$count} portal
  *[other] {$count} portals
}
history-row-townpct = {PERCENT_INT($percent)} in town
history-row-totaldur-abandoned = ???
  .title =
    Map run abandoned - you went offline without returning to town first!

    Sadly, when you go offline without returning to town, Mapwatch cannot know how long you spent in the map. Times shown here will be wrong.

    See also https://github.com/mapwatch/mapwatch/issues/66

history-side-labtrial = Labyrinth trial
history-side-vaalarea = Vaal side area
history-side-zana = Zana

history-npc-einhar = Einhar, Beastmaster
history-npc-alva = Alva, Master Explorer
history-npc-niko = Niko, Master of the Depths
history-npc-jun = Jun, Veiled Master
history-npc-cassia = Sister Cassia
history-npc-tane = Tane Octavius
history-npc-delirium = Delirium Mirror
history-npc-legion = Legion General

history-conqueror-name = {$conqueror ->
  [baran] Baran, the Crusader
  [veritania] Veritania, the Redeemer
  [alHezmin] Al-Hezmin, the Hunter
  [drox] Drox, the Warlord
  *[other] Unknown-Conqueror-ID "{$conqueror}", the Bugged
}
history-conqueror-taunt = {history-conqueror-name}: Taunt {$taunt}
history-conqueror-fight = {history-conqueror-name}: Fight

### Maps ###

maps-header-name = Name
maps-header-region = Region
maps-header-tier = Region
maps-header-meandur = Average
maps-header-portals = Portals
maps-header-count = # Runs
maps-header-bestdur = Best

maps-row-tier = (T{$tier})
maps-row-portals = {$count ->
  [one] {$count} portal
  *[other] {$count} portals
}
maps-row-count =
  {$count ->
    [one] ×{$count} run
    *[other] ×{$count} runs
  }
maps-row-meandur = {$duration} per map
maps-row-bestdur = {$duration} per map

### Encounters ###

encounters-header-name = Encounters
encounters-header-count = #
encounters-header-percent = % of {$count} maps

encounters-row-count = ×{$count}
encounters-row-percent = {PERCENT($percent)}

encounters-name-abyssaldepths = Abyssal Depths
encounters-name-vaalarea = Vaal side areas
encounters-name-uniquemaps = Unique Maps
encounters-name-labtrials = ({$count}/6) Labyrinth Trials
encounters-name-blightedmaps = Blighted Maps
encounters-name-conquerors = Conqueror Fights
encounters-name-conquerors-title =
  .title = excluding Sirus
encounters-name-zana = Zana
encounters-name-einhar = Einhar
encounters-name-alva = Alva
encounters-name-niko = Niko
encounters-name-jun = Jun
encounters-name-cassia = Sister Cassia
encounters-name-delirium = Delirium
encounters-name-tane = Tane Octavius
encounters-name-legion = Legion Generals

### Export TSV Spreadsheet ###

export-tsv-help = Copy and paste the <b>Tab-Separated Values</b> below into your favorite spreadsheet application.
export-tsv-header-history = History:
export-tsv-header-maps = Maps:
export-tsv-header-encounters = Encounters:

### Export Google Sheets ###

export-gsheets-beta =
  Beware: Mapwatch's Google Sheets export is new <br>
  and still only <code>BETA</code> quality. Expect bugs.
export-gsheets-login-help =
  Login to your Google account below to create a spreadsheet with your Mapwatch data.
export-gsheets-login = Login to Google Sheets
export-gsheets-logout = Logout of Google Sheets
export-gsheets-disconnect = Disconnect Google Sheets
export-gsheets-disconnect-help = Log out everywhere, and remove Mapwatch from your Google account.

export-gsheets-new = Write {$count} maps to a new spreadsheet
export-gsheets-update = Write {$count} maps to spreadsheet id:
export-gsheets-success = Export successful!
export-gsheets-success-link = View your spreadsheet.

### Shared utilities ###

util-filter-none = Unhide all maps
util-filter-league = Hide pre-{-league} maps

util-search-span =
  .title =
    To see searchable text for a map-run, hover over its region on the history screen.
    Search accepts regular expressions.

util-search-input =
  .placeholder = map name

util-goal-none = No time goal
util-goal-best-today = Goal: today's best
util-goal-mean-today = Goal: today's average
util-goal-best-session = Goal: session best
util-goal-mean-session = Goal: session average
util-goal-best-alltime = Goal: all-time best
util-goal-mean-alltime = Goal: all-time average
util-goal-exactly = Goal: exactly...
util-goal-exactly-input =
  .placeholder = "5:00" or "300" or "5m 0s"

notfound = 404
