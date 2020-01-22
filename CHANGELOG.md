# PoE Mapwatch: updates

All substantial Mapwatch changes.

## [Unreleased]
### Beta/experimental
- [Speech](https://mapwatch.erosson.org?enableSpeech=1)

---
## 2020-01-22
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
