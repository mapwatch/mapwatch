# [Mapwatch](https://mapwatch.erosson.org)

[Download Mapwatch](https://github.com/mapwatch/mapwatch/releases/latest), or [try the web version](https://mapwatch.erosson.org).

[![build and deploy](https://github.com/mapwatch/mapwatch/workflows/push-deploy/badge.svg)](https://github.com/mapwatch/mapwatch/actions?query=workflow%3Apush-deploy)
[![Dependabot Status](https://api.dependabot.com/badges/status?host=github&repo=mapwatch/mapwatch)](https://dependabot.com)

Give me your [Path of Exile](https://www.pathofexile.com) `Client.txt` log file, and I'll give you some statistics about your recent mapping activity.

Then, [if you're using the Mapwatch app](https://github.com/mapwatch/mapwatch/releases/latest), leave me open while you play - I'll keep watching, no need to upload again.

[Run an example now!](https://mapwatch.erosson.org?tickStart=1526927461000&logtz=0&example=stripped-client.txt#/)

Or, screenshots (slightly outdated):

[![Screenshot 1](https://i.imgur.com/PPRbLlZ.png)](https://imgur.com/a/VhFtZbU)

[![Screenshot 2](https://i.imgur.com/DrMCKZD.png)](https://imgur.com/a/VhFtZbU)

### It's not updating while I play - I have to re-upload client.txt to see changes.

You must now [download Mapwatch](https://github.com/mapwatch/mapwatch/releases/latest) to see updates while you play. [More information](https://github.com/mapwatch/mapwatch/blob/master/WATCHING.md).

### Is this legal?

[Yes, says GGG.](https://imgur.com/44uuaiz)

### Is this safe/secure? I don't want to download/run strange executables.

The web version of Mapwatch is safe; you can analyze your mapping history with no downloads or executables.

[Sadly, Mapwatch updating while you play is no longer easily available in any web browser.](https://github.com/mapwatch/mapwatch/blob/master/WATCHING.md) You'll need to [download Mapwatch](https://github.com/mapwatch/mapwatch/releases/latest) for that feature.

### Is this private?

Mostly yes. Nothing in your `client.txt` ever leaves your computer. Once Mapwatch has loaded, it'll even work offline.

Mapwatch tells Google Analytics how long you've spend on the page and when you finish a map. The developer's goal here is to see averages of all Mapwatch users, and to gather debugging information - nothing evil.

If Google Analytics tracking bothers you, [feel free to turn it off.](https://tools.google.com/dlpage/gaoptout)

### Why?

Seeing how much time I spend in each map, and how much time I waste screwing around in town, helps me play more efficiently. Maybe it'll help you too. Also, numbers are fun.

### How do Zana missions work?

They're treated as "side areas", like abyssal depths or trials, not a separate map run. A map with a Zana mission adds 1, not 2, to your maps-completed-today count.

### Any similar tools?

* [Path of Maps](http://pathofmaps.com/) allows you to track loot from each map. It's less automatic, it takes some extra interaction/time during each map, but it can track things that Mapwatch doesn't.
* [Livesplit](https://github.com/brandondong/POE-LiveSplit-Component) times acts 1-10 and the Labyrinth with no extra interaction, much like Mapwatch. I don't think Livesplit times your maps.
* [Exilence](https://github.com/viktorgullmark/exilence) and [Exile Diary](https://github.com/briansd9/exile-diary) automatically track not just maps, but loot and other statistics.
  * They're both great tools, and might be more useful for you than Mapwatch. Try them out!
  * These tools must always be open while playing PoE to analyze your maps - if you run a map while these tools are closed, it's not tracked; Mapwatch can always fully analyze your mapping history, whether or not it was running at the time. Also, Mapwatch existed before both of these tools.
* Any others out there I'm not aware of?

### Does this track acts 1-10?

No. [Livesplit](https://github.com/brandondong/POE-LiveSplit-Component)'s already good at those.

### The map I just finished isn't included in today's statistics yet.

Mapwatch probably doesn't know you're done with the map yet. Mapwatch thinks a map is done when you:

* Leave town. Either enter a new map, or enter a non-map zone like the Aspirants' Plaza.
* Or, wait 30 minutes. When you don't enter any new zones for a while, Mapwatch will assume you're done playing.
  * One exception: The Simulacrum (Delirium) takes 60 minutes, instead of 30.

Returning to town does not end a run - maybe you died or you're dropping off loot, but you aren't done with the map yet.

Restarting the game does not end a run - maybe it crashed, but you're restarting and aren't done with the map yet.

The idea is that your map runs will (eventually) be counted properly by just playing normally.

### I ran two Vault maps (for example) in a row, but Mapwatch thinks I only ran one map.

Unfortunately, I can't fix this. PoE's log file sometimes doesn't have enough information to tell two maps apart. Sorry.

**Why?** The log file tells us the *zone name* and the *server address* (ex. "Vault@127.0.0.1:6112"). The server is assigned randomly, and there's lots of them, so usually we can tell the difference between two map-instances with the same name. Not always, though - if two map-instances in a row happen to be on the same server, they might look the same to us.

This has been pretty uncommon, in my experience. It could be more or less common depending on your location/login gateway. If it bothers you enough, the workaround is to avoid running the same kind of map twice in a row. Maps with different names will never be confused.

### Will Mapwatch work if I run PoE in a language other than English?

Yes! ~~Mapwatch itself is English-only, but~~ you can play Path of Exile in any language - Mapwatch should be able to understand your Client.txt.

If your language seems broken, please file a bug. I usually test Mapwatch in English, but I want to know if your language isn't working!

[Want to help translate Mapwatch to your language?](TRANSLATING.md)

### [My Harvest encounter rate seems low?](https://github.com/mapwatch/mapwatch/issues/183)

**Your true Harvest encounter rate is higher than Mapwatch says.**

Mapwatch tracks all Harvest encounters where Oshabi speaks. This works well for most of the game's NPC encounters - unfortunately, [Oshabi is often quiet, at random](https://github.com/mapwatch/mapwatch/issues/183). Mapwatch can't detect harvests where Oshabi happens to be quiet (nor can any other client.txt-based tool). Sadly, Mapwatch cannot fix this.

Oshabi's much more vocal if you never talk to her/never complete her tutorial quest. This allows much better Mapwatch harvest tracking.
