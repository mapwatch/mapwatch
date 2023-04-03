# PoE Mapwatch: updates

All substantial Mapwatch website changes.

---

## 2023-04-03
- Changing the log file size now works properly. ("Analyze only the last 20 MB of history")
- Parse 40 MB of logs by default, instead of 20 MB.

## 2022-09-28
- The Searing Exarch, Eater of Worlds, Black Star, and Infinite Hunger encounters are now tracked.
- Your deaths per map are now tracked.

## 2022-08-16
- Game data is now pulled using [poe-dat-viewer](https://snosme.github.io/poe-dat-viewer/), instead of PyPoE (RIP). Things should generally be much more up-to-date now.
- Fixed this league's map icons.
- Find and display map level, when possible.

## 2021-11-17
- Ritual encounters are now tracked.
  - Thanks to [Perotti28](https://github.com/Perotti28/RitualReminder) for letting me know this was possible!
- Added an audio reminder to spend your Ritual tribute. You'll hear "did you spend your Ritual tribute?" when returning to town after clearing 3 or more Rituals.
  - Mapwatch cannot detect if you've *actually* spent your Ritual tribute, so there will be some false positives. If you forget as often as I do, it's totally worth it.

## 2021-11-10
- Fixed broken side area icons.
- Replaced gamepedia wiki links with poedb.
- Updated map region icons.

## 2021-10-10
- Built the infrastructure needed to translate Mapwatch to non-English languages.
  - [Want to help translate Mapwatch to your language?](https://github.com/mapwatch/mapwatch/blob/master/TRANSLATING.md)
  - We've been able to parse non-English log files for a while. This is for the Mapwatch user interface.

## 2021-08-20
- Expedition NPCs are now tracked.
- Excluded Royale from league buttons.
- Fixed some broken encounter icons.

## 2021-06-19
- Fixed a bug preventing Mapwatch from reading Russian language logs.

## 2021-05-09
- Retreating just before the Trialmaster boss fight is now correctly tracked as a boss spawn.
  - Does it sting to have gotten so close last time?

## 2021-05-04
- The Trialmaster boss fight is now correctly tracked.
  - It is very unlikely you found a bug with Trialmaster spawn rates. Please don't use this as evidence for your Angry Reddit Thread.
- Trialmaster win/loss/retreat/abandon rates are now tracked on the Encounters screen.
- Lab trials opened with an offering in the map device are now tracked.

## 2021-04-29
- Added a duration to Trialmaster encounters. Trialmaster time is counted as time spent in a side area.
- The Trialmaster encounter in a Zana map is now correctly split from the Trialmaster encounter in the parent map.

## 2021-04-20
- A few more Trialmaster tracking fixes. Thank you for your bug reports!
- Each map run now has a link to its `client.txt` source text.
  - This is useful for better understanding what's in `client.txt`, understanding how Mapwatch works, or reporting Mapwatch bugs.

## 2021-04-19
- A few Trialmaster tracking fixes.

## 2021-04-18
- The Trialmaster is now tracked, including victory/defeat and modifiers.
  - Very kind of The Trialmaster to be so noisy for me.
  - If you see any obnoxious red text indicating a modifier Mapwatch doesn't know about, please report it to the developer - thanks! https://github.com/mapwatch/mapwatch/issues
- Inscribed ultimatums are now tracked.
- The new Harvest boss fight area is now tracked.

## 2021-04-10
- The Encounters page now has text discouraging its use in Angry Reddit Threads.
- The Encounters page is now split into two tables: encounters restricted to normal maps, and encounters in all endgame areas.
  - A "normal map" is anywhere a master can spawn: non-blighted, non-unique, endgame areas with an atlas region; plus Shaper guardian maps.
  - Hopefully this makes Angry Reddit Threads somewhat more accurate.
- Changed map search strings to better distinguish "normal maps" from other endgame areas.
- The example link on the front page works again.

## 2021-03-14 🥧
- The Laboratory heist contract is now correctly distinguished from the Laboratory map.
- NPCs encountered in Zana maps now have a Zana icon next to their names. This helps distinguish "natural" Oshabi encounters from encounters that may have been forced by Zana, for example.

## 2021-03-13
- Syndicate and Mastermind hideouts are now tracked.
- The Domain of Timeless Conflict is now tracked.
- The Labyrinth is now tracked.
  - This one was kind of tricky. [Please report any bugs](https://github.com/mapwatch/mapwatch/issues); thanks!
- Fixed wiki links for Eye of the Storm and The Maven's Crucible.
- The Encounters page now tracks Grand Heists, Heist contracts, and non-Heist maps.
- Fixed a bug when exporting to certain Google spreadsheets.

## 2021-03-09
- Enabled exporting your map data to Google Sheets. It's on the history screen, next to the TSV-export button.

## 2021-02-07
- Sirus map encounters are now tracked.

## 2021-02-04
- The Encounters page now includes a disclaimer about [Harvest tracking inaccuracy](https://github.com/mapwatch/mapwatch#my-harvest-encounter-rate-seems-low).

## 2021-01-31
- The Maven encounters are now tracked.
- The Envoy encounters are now tracked.
- Oshabi and Heart of The Grove encounters are now tracked, and correctly distinguished from one another.
  - If Oshabi is silent during a harvest, Harvest unfortunately cannot be tracked.
  - ~~Once you've beaten Heart of the Grove, Oshabi will always be silent and unfortunately cannot be tracked (I think).~~
- The Maven's Crucible is now tracked.
- Removed the Delirium feature-flag; it's now always tracked.
- Fixed a bunch of localization bugs introduced with 2021-01-18's changes. Searching for NPCs now works, for example.

## 2021-01-18 (and some earlier stuff)
- Data exported from PoE game files (regions, names, images, hideouts...) is now updated [automatically](https://github.com/erosson/pypoe-json) whenever PoE is patched, so it won't appear in this changelog anymore.
- The "hide pre-(LEAGUE)" button is now updated automatically each league, so it won't appear in this changelog anymore.
- The "hide pre-(LEAGUE)" button now supports events like Flashback and Mayhem.

## 2020-10-03
- Heist NPCs are now tracked.
- Heist contracts are now distinguished from grand heists.
- You can now search for `heist-contract` or `grand-heist`, or exclude heists by searching for `map:`.

## 2020-09-29
- Added links to the Path of Exile wiki for the current map, and on the history page when searching for/linking to a single specific map.
- Added divination card and regional item drops for the current map, and on the history page when searching for/linking to a single specific map.

## 2020-09-22
- Updated map regions for Heist league.
- Heist contracts and bosses are now tracked.

## 2020-09-18
- Updated "hide pre-Harvest maps" button for Heist league.

## 2020-08-14
- Updated map regions for Harvest league.
- The Thaumaturgical Hideout now works correctly.

## 2020-06-24
- Delirium encounters are now tracked.

## 2020-06-17
- Updated "hide pre-Delirium maps" button for Harvest league.

## 2020-04-17
- [Spreadsheet export](https://mapwatch.erosson.org/#/history/tsv) now includes data from the Maps and Encounters pages.
- In addition to copy-pasting TSV spreadsheets, [you can now export your map data to Google Sheets](https://mapwatch.erosson.org/#/gsheets?gsheets=1).
  - Google Sheets export is still new, likely has bugs, and is turned off by default. You can try beta-testing it by clicking the link above.

## 2020-04-16
- Created an [encounters page](https://mapwatch.erosson.org/#/encounter) with statistics for side areas and NPCs.
- Improved map search: you can now search for side areas, unique maps, and specific conqueror encounters, among other changes.
  - Text used for search is now visible when hovering over its atlas region on the history screen.
- Speech volume is now only on the setup and settings pages; removed from all other pages.
- Minor tweaks to the search form at the top of most pages.
- Uber Elder is now correctly tracked, and is no longer combined with the Shaper map.
  - Both zones are named "The Shaper's Realm"; we use the Shaper's voicelines to tell them apart.
- Search links for map names with parentheses and other special characters should now work.

## 2020-04-10
- [Released a downloadable version of Mapwatch](https://github.com/mapwatch/mapwatch/releases/latest).
  - Sadly, map-updates while you play will soon be [unavailable](https://github.com/mapwatch/mapwatch/blob/master/WATCHING.md) in all web browsers. Only the Mapwatch app will support this feature.
  - The Mapwatch website is not going away.
  - Changes to the Mapwatch website (ie. anything in this changelog) immediately affect the Mapwatch app too. [Changes that only affect the Mapwatch app will be on its releases page](https://github.com/mapwatch/mapwatch/releases).

## 2020-03-31
- The Simulacrum now stops tracking after 60 minutes. Other maps are unchanged, still stopping after 30 minutes.
- Fixed Veritania's encounter counting (for real this time).

## 2020-03-30
- Fixed a bug preventing Temple of Atzoatl tracking.

## 2020-03-19
- The Simulacrum is now tracked.
- Delirium encounters can now be tracked. This is off by default - seeing delirium in every map is not useful - but if you like, [you can turn it on](https://mapwatch.erosson.org?deliriumEncounter=1).
- Legion encounters *with a general* are now tracked.
  - It's not possible to track Legion encounters *without a general*, since tracking is based on NPC dialogue. Metamorph tracking is also not possible, since Tane is usually quiet. Sorry!
- Betrayal encounters are now tracked using dialogue from all Syndicate members, not just Jun.
  - Fixed tracking for Betrayal encounters where Jun herself happens to be quiet.
  - Dialogue for all Syndicate members is shown when mousing over a Betrayal encounter, not just Jun's dialogue.
- Maps runs where you go offline without returning to town are now tracked.
  - It's impossible to know how long you spent in a map when this happens. Still, Mapwatch tries its best.
  - Even without durations, it's helpful to show these maps for [conqueror tracking](https://github.com/mapwatch/mapwatch/issues/66).

## 2020-03-12
- Updated "hide pre-Metamorph maps" button for Delirium league.
- Enabled speech: audio announcements upon map completion. Muted by default, but there's a volume control at the start page and settings page.
  - If speech causes problems, [you can turn it off for now](https://mapwatch.erosson.org?enableSpeech=0).
- Added a [privacy policy](#privacy).
- Removed conqueror tracking from the timer.
  - With the improvements to in-game conqueror tracking, I don't think this is necessary anymore. If you disagree, [you can re-enable it for now.](https://mapwatch.erosson.org?conquerorStatus=1)

## 2020-01[-](# "Happy birthday to me~")23
- Fixed a bug that broke the summary at the top of the history page when before/after times were set.
- Conqueror status now shows an icon with the region of your last conqueror encounter and regions of all past conqueror encounters.

## 2020-01-22
- You can now export your map data as tab-separated values, for easy use in spreadsheets. Look for the link at the bottom of the history page.
- Conqueror-status now has a link to all maps with conquerors.

## 2020-01-19
- Breachlord domains and Shaper guardian maps are now correctly tracked.
- Fixed a bug that caused [speech](https://mapwatch.erosson.org?enableSpeech=1) to happen more often than intended.
- Fixed a short-lived conqueror-counting bug.

## 2020-01-18
- Atlas regions are now displayed for each map. [/u/Kadoich inspired the icons; thank you!](https://www.reddit.com/r/pathofexile/comments/emmvln/a_map_stash_tab_qol_featuring_region_highlighting/)

## 2020-01-17
- Added a settings screen.
- You can now choose another client.txt file from the settings screen without reloading the page.

## 2020-01-16
- Fixed Veritania's encounter counting.
- Conqueror counting now works immediately, before your current map is finished.

## 2020-01-15
- The timer now displays how many times you've encountered each conqueror since you last fought Sirus.
- Blighted maps are now tracked.
  - We use Cassia's dialogue to detect if a map is blighted, which means we can't tell if it's blighted until it's partially complete.
- You can now search for NPCs by name, blighted maps, and atlas regions (ex. "valdo's rest").
- Conqueror dialogue should now be correctly parsed for languages with grammatical genders.

## 2020-01-14
- The Sirus, Awakener of Worlds fight is now tracked.

## 2020-01-13
- Master encounters are now tracked.
- Conqueror encounters and taunt-counts are now tracked.
- Maps with fragments (Atziri, Pale Court, Shaper, Elder) are once again correctly tracked again.
  - We might mess up Shaper vs. Uber Elder for now, since their arenas have the same name.

## 2020-01-12
- Side areas now have icons.
- Vaal side areas and labyrinth trials now have labels.
- Mapwatch now works even if you're not playing PoE in English: it understands log files in any language supported by PoE.
  - The text within Mapwatch's interface/website is still only in English.
  - Foreign logfiles aren't well-tested, since I only speak English. Please let me know if they work/don't work for you!
- Fixed several timezone bugs. In particular, the "run an example" link now works in all timezones.
- The timer next to "last entered" now correctly shows how long it's been since you entered that area.
- Big log processing redesign. There should be no visible changes from this one, but watch out for new bugs.

## 2020-01-08
- Updated map names and tiers for Metamorph league.
- Revamped how map names and tiers are defined. They're now datamined from game files, instead of manually listed and updated.

## 2019-12-13
- Updated "hide pre-Blight maps" button for Metamorph league.
- **Beware**: map names and tiers have *not* yet been updated. GGG didn't post them in advance this time, and I probably haven't unlocked the whole atlas yet; my play time's limited this time around. Mapwatch might be broken for a few days; sorry.

## 2019-09-18
- Website moved to [mapwatch.erosson.org](https://mapwatch.erosson.org). The old github.io site will automatically send you here.
- Refactored and compressed website code. Things might run a little faster, but otherwise, this should cause no visible changes.

## 2019-09-04
- Updated "hide pre-Legion maps" button for Blight league.
- Updated map names/tiers for Blight league, based on [this post](https://www.reddit.com/r/pathofexile/comments/cx82nl/heres_a_preview_of_the_atlas_of_worlds_in_path_of/).

## 2019-08-06
- Better date/time formatting on the history page.
- "Last entered" now shows how long ago it was updated. This will make things clearer if Mapwatch isn't seeing any updates to your PoE log file.

## 2019-08-04
- Fixed Chinese translations.
- The Maps page can now sort.

## 2019-07-10
- The Glimmerwood Hideout should now work correctly.

## 2019-06-12
- The "hide pre-Legion maps" button should now work correctly.

## 2019-06-05
- Updated "hide pre-Synthesis maps" button for Legion league.
- Updated map names/tiers for Legion league, based on [this post](https://www.reddit.com/r/pathofexile/comments/bwhiyi/heres_a_preview_of_the_atlas_of_worlds_in_path_of/epxlf0g/).
- Perandus Manor and Doryani's Machinarium should now be tracked correctly.

## 2019-03-11
- All the new Synthesis hideouts should now behave correctly.

## 2019-03-06
- Updated "hide pre-Betrayal maps" button for Synthesis.
- Updated map names/tiers for Synthesis league, based on [this post](https://www.reddit.com/r/pathofexile/comments/ax29hh/complete_synthesis_atlas_tiered_labeled_colored/).

## 2018-12-15
- All new hideouts in PoEDB, even the secret ones, should now behave correctly.

## 2018-12-09
- The beta/experimental [speech feature](https://mapwatch.erosson.org?enableSpeech=1) now has a volume setting. Second try, oops - now it only appears when speech is enabled.
- The new hideouts from Helena's hideout list should now behave correctly.

## 2018-12-07
- Updated "hide pre-Delve maps" button for Betrayal.
- Updated [map names, map icons](https://www.pathofexile.com/forum/view-thread/2254801/page/1#p15971585), and [map tiers](https://www.pathofexile.com/forum/view-thread/2253540) for Betrayal. Thanks for the heads up, GGG!
- ~~The beta/experimental [speech feature](https://mapwatch.erosson.org?enableSpeech=1) now has a volume setting.~~

## 2018-09-16
- The Hall of Grandmasters should now be tracked correctly.
- [Lots of internal code changes](https://github.com/mapwatch/mapwatch/issues/28). None of these changes should be visible to you, or make the site behave any differently - let me know if anything broke today!

## 2018-09-03
- Improved speech lines.

## 2018-08-29
- Updated "hide pre-Incursion maps" button for Delve.

## 2018-07-04
- The [overlay view](https://mapwatch.erosson.org/#/overlay) is no longer experimental, and is now linked from the timer.
- Goals/time-differences are no longer experimental. Find them at the top of the timer and history pages.

## 2018-07-03
- Redesigned this changelog. You can now be notified of changes via [RSS](https://mapwatch.erosson.org/rss.xml) or [email](https://feedburner.google.com/fb/a/mailverify?uri=mapwatch).

## 2018-06-30
- The Apex of Sacrifice, The Alluring Abyss, The Pale Court, and The Shaper's Realm are now tracked.
- Added an [experimental speech feature](https://mapwatch.erosson.org?enableSpeech=1).

## 2018-06-09
- The Temple of Atzoatl is now tracked when entered from your hideout.
- Zana dailies now have an icon.
- Added an [experimental overlay view](https://mapwatch.erosson.org/#/overlay). This minimal view aims to be better for streaming, or playing on only one monitor.

## 2018-06-01
- Added a "hide pre-Incursion maps" button.

## 2018-05-30
- Session tracking's now available for everyone.

## 2018-05-28
- Created an experimental time-goals/splitting feature. Hidden by default. Beta: may change/disappear. [Feel free to try it out.](https://mapwatch.erosson.org?enableGoals=1)

## 2018-05-25
- Created this changelog.
- Broke existing urls for search. (It's soon enough that I don't expect it to bother anyone.)
- Created an experimental session-tracking feature. Hidden by default. Beta: may change/disappear. [Feel free to try it out.](https://mapwatch.erosson.org?enableSession=1)
- Added basic support for [Chinese-language log files](https://mapwatch.erosson.org?tickStart=1526242394000&example=chinese-client.txt). [Want your language supported?](https://github.com/mapwatch/mapwatch/issues/12)

## 2018-05-23
- Initial release and [announcement](https://www.reddit.com/r/pathofexile/comments/8lnctd/mapwatch_a_new_tool_to_automatically_time_your/).
