---
title: "[ggpk-notify] GGPK data has changed - datamine is out of date"
---
Looks like they patched Path of Exile! It's time to run `cd packages/datamine && TODO:yarn-one-command-to-fetch-and-export`.

[The ggpk-notify robot][bot] saw that `steamctl depot info -a 238960 -d 238961` no longer matches [`steam-depot-info.txt`][info.txt].
<details><summary>What's changed?</summary>
<code>
{{ env.STEAM_DEPOT_INFO_NEW }}
</code>
</details>

[bot]: https://github.com/mapwatch/mapwatch/blob/master/.github/workflows/ggpk-notify.yml
[info.txt]: https://github.com/mapwatch/mapwatch/blob/master/packages/datamine/steam-depot-info.txt
