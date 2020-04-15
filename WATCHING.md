## Mapwatch isn't updating while I play - I have to re-upload client.txt to see changes.

**[Download Mapwatch](https://github.com/mapwatch/mapwatch/releases/latest) to see updates while you play!**

If you've used Mapwatch in the past, you'll remember the website used to update while you play. Sadly, Chrome version 81 broke this feature (2020 April 10-ish). **Updates while you play are no longer easily available in any web browser.** [The downloadable version of Mapwatch](https://github.com/mapwatch/mapwatch/releases/latest) now supports this.

For one-time analysis of your mapping history, the Mapwatch website still works well. It won't be going away.

Related Mapwatch issues: [#11](https://github.com/mapwatch/mapwatch/issues/11), [#51](https://github.com/mapwatch/mapwatch/issues/51), [#70](https://github.com/mapwatch/mapwatch/issues/70)

### You said "not *easily* available in any web browser". I don't want to download/execute your app, I want updates while I play, and I have some technical skills.

Are you sure? [Downloading Mapwatch](https://github.com/mapwatch/mapwatch/releases/latest) is easier, I promise.

---

If you're really sure: I admire your refusal to trust strange executables. [The `nativefs` web version of Mapwatch might work for you](https://mapwatch.erosson.org#?backend=www-nativefs), but you'll need to do a little extra work first.

Run the following in your command prompt:

    mklink /H "C:\Users\%USERNAME%\Documents\My Games\Path of Exile\mapwatch.erosson.org---Client.txt" "C:\Program Files (x86)\Grinding Gear Games\Path of Exile\logs\Client.txt"

This creates a *hardlink* - kind of a fancy shortcut - from your `client.txt`, to a new file in your loot filter directory. Type `mklink` in the command prompt to see `mklink`'s help text.

You might need to change the hardlink's target if PoE is installed somewhere else. For example, if you installed PoE through Steam:

    mklink /H "C:\Users\%USERNAME%\Documents\My Games\Path of Exile\mapwatch.erosson.org---Client.txt" "C:\Steam\steamapps\common\Path of Exile\logs\Client.txt"

You're done! Use [the `nativefs` version of Mapwatch](https://mapwatch.erosson.org#?backend=www-nativefs) with the new hardlink.

---

To see why all this is necessary, [try opening your original `client.txt` file with the `nativefs` version of Mapwatch](https://mapwatch.erosson.org#?backend=www-nativefs). You'll probably get an error message: [`mapwatch.erosson.org can't open files in this folder because it contains system files`](https://user-images.githubusercontent.com/238846/71852113-fb2d2b80-30a5-11ea-84aa-79270a63b81f.png). Chrome is picky about the location of files accessed via `nativefs`, but only `nativefs` allows the Mapwatch website to see changes to your `client.txt` while you play. Chrome/`nativefs` is happier with the loot filter directory, so we create a hardlink there, allowing the Mapwatch website to update while you play.

Sorry for all the trouble. [#51](https://github.com/mapwatch/mapwatch/issues/51) has more gory technical details.

---

If you don't know how to open a command prompt, don't understand what I'm talking about above, or the above steps otherwise don't work for you: [please download Mapwatch instead](https://github.com/mapwatch/mapwatch/releases/latest)!
