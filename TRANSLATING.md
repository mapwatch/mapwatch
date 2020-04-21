## Translating Mapwatch

Thank you for your interest in helping! The Mapwatch developer can automatically translate PoE log files using information from the PoE game files, but translating the rest of the Mapwatch interface is only possible with your help.

[Here are all of Mapwatch's translation files.](https://github.com/mapwatch/mapwatch/tree/master/packages/www/src/lang/)
You'll need to create one of these files for your language. These are [Fluent](https://projectfluent.org/) files with embedded HTML.

[Here's the English translation file, written by the Mapwatch developer.](https://github.com/mapwatch/mapwatch/tree/master/packages/www/src/lang/en-us.ftl.properties)
Copying this file might help you get started.

Once the translation's complete, [the developer will add a few lines of code here](https://github.com/mapwatch/mapwatch/tree/master/packages/www/src/lang/messages.js) to enable your language. You'll also need to add a `settings-locale-entry-` to the English translation file for your language for it to appear on the settings page.

Partial translations are still useful - if any lines are missing, we'll fall back to the English version.

You can test your translations by [running the Mapwatch website on your machine](https://github.com/mapwatch/mapwatch/blob/master/CONTRIBUTING.md). (I'm working on adding a way for you to test them more easily!)

[This link](https://mapwatch.erosson.org/?debugLocalized=1) highlights all translatable text - if you find any text there that *isn't* highlighted, it can't yet be translated. Also, spreadsheet export cannot yet be translated.

If you have questions for the developer while translating, [feel free to ask](https://github.com/mapwatch/mapwatch/issues). Thank you for your help!
