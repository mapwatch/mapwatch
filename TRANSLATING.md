## Translating Mapwatch

Thanks for your interest in translating Mapwatch! The Mapwatch developer can automatically translates PoE log files, but translating the rest of the Mapwatch interface is only possible with your help.

To get started, **[try this live-translation tool](https://mapwatch.erosson.org/#/debug/translator)!**

---

[Here's the original English translation file, written by the Mapwatch developer.](https://github.com/mapwatch/mapwatch/tree/master/packages/www/src/lang/en-us.ftl.properties)
A complete translation converts all text in that file.

[Here are all of Mapwatch's translation files.](https://github.com/mapwatch/mapwatch/tree/master/packages/www/src/lang/)
You'll need to create one of these files for your language. These are [Fluent](https://projectfluent.org/) files with embedded HTML.
(The developer will read all HTML you embed before running any of it.)

Once the translation's complete, [the developer will add a few lines of code here](https://github.com/mapwatch/mapwatch/tree/master/packages/www/src/lang/messages.js) to enable your language. You'll also need to add a `settings-locale-entry-` to the English translation file for your language for it to appear on the settings page.

Partial translations are still useful - if any lines are missing, we'll fall back to the English version.

[This link](https://mapwatch.erosson.org/?debugLocalized=1) highlights all translatable text - if you find any text there that *isn't* highlighted, it can't yet be translated. Also, spreadsheet export cannot yet be translated.

---

If you have questions for the developer while translating, [feel free to ask](https://github.com/mapwatch/mapwatch/issues). Once you're done translating, [send your translation to the developer](https://github.com/mapwatch/mapwatch/issues). Thanks so much for your help!
