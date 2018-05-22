# [Mapwatch](https://erosson.github.io/mapwatch)

[![Build Status](https://travis-ci.org/erosson/mapwatch.svg?branch=master)](https://travis-ci.org/erosson/mapwatch)

Give me your [Path of Exile](https://www.pathofexile.com) `Client.txt` log file, and I'll give you some statistics about your recent mapping activity.

Then, [if you're using Google Chrome](https://chrome.google.com), leave me open while you play - I'll keep watching, no need to upload again.

### Example output

[Run an example now!](https://erosson.github.io/mapwatch/?tickStart=%3CMon%20May%2021%202018%2018:31:01%20GMT-0400%20(EDT)%3E&example=stripped-client.txt#/)

Or, screenshots:

[![Screenshot 1](https://i.imgur.com/PPRbLlZ.png)](https://imgur.com/a/VhFtZbU)

[![Screenshot 2](https://i.imgur.com/DrMCKZD.png)](https://imgur.com/a/VhFtZbU)

### Is this legal?

[GGG says yes.](https://imgur.com/44uuaiz)

### Will this give me viruses?

No. There is no executable to download and run; it's just a web page.

### It's not updating while I play - I have to re-upload client.txt to see changes.

The live-updating part only works in Chrome - Firefox and/or IE do *not* work.

I could create a downloadable version where this would be more reliable, if people are interested, but I hope it's not necessary.

### The map I just finished isn't included in today's statistics yet.

Mapwatch probably doesn't know you're done with the map yet. Mapwatch thinks a map is done when you:

* Leave town. Either enter a new map, or enter a non-map zone like the Aspirants' Plaza.
* Or, wait 30 minutes. When you don't enter any new zones for a while, Mapwatch will assume you're done playing.

Returning to town does not end a run - maybe you died or you're dropping off loot, but you aren't done with the map yet.

Restarting the game does not end a run - maybe it crashed, but you're restarting and aren't done with the map yet.

The idea is that your map runs will (eventually) be counted properly by just playing normally.

### I ran two Vault maps (for example) in a row, but Mapwatch thinks I only ran one map.

Unfortunately, I cannot fix this. PoE's log file doesn't have the information I need to fix this. Sorry.

**Why?** The log file tells us the *zone name* and the *server address* (ex. "Vault@127.0.0.1:6112"). The server is assigned randomly, and there's lots of them, so usually we can tell the difference between two map-instances with the same name. Not always, though - if two map-instances in a row are on the same server, they might look the same to us.

If this bothers you enough, the workaround is to avoid running the same kind of map twice in a row. Maps with different names will never be confused.
