## Contributing to Mapwatch

Happy to consider pull requests. Talk to @erosson before spending lots of time on one - accepting pull requests is not a sure thing, even when there's an open issue.

# Multiple Languages

Mapwatch is tested with the English PoE client. Thanks to a player like you, Mapwatch also supports the Chinese client! See #10 and https://github.com/mapwatch/mapwatch/commit/a3165dca5a4829bb9e87145ab5d7a01758e19ed9. 

If you'd like your language supported, I'll need your help! Please send me:

* a list of town names
* a list of map names
* an example of a "you have entered [area]" log line (other log lines are likely to be the same, I think?)
* optionally, master mission zones found inside maps [ex. "haunted pit", etc. for haku]
* part of your client.txt, for me to test things with. A few hours of play spent in maps is plenty.

http://poedb.tw/ might be helpful.

[Here's the document I needed to add Chinese support.](https://docs.google.com/spreadsheets/d/1G2cPYZAldc7axDcH1-U83fNlJ18Rd2yo96YZL2zE3Lc/edit#gid=0) I'll need something like this for your language.

Thanks for your help!

# Development

One-time setup (if this is broken, please talk to @erosson or file an issue):

* fork and clone the repository
* install [Node](https://nodejs.org/en/), [Yarn](https://yarnpkg.com/en/docs/install)
* most Mapwatch code is written in Elm, so install [Elm](https://guide.elm-lang.org/install.html). Configure your editor to handle Elm code and run [elm-format](https://github.com/avh4/elm-format) on save. I mostly use [Atom](https://atom.io/packages/language-elm).
* finally, run `yarn` and your repository should be ready to use

Developing:

* run the website locally: `yarn dev:www`. Most website code lives in `packages/www/src`
* create a production build of the website: `yarn build:www`
* create a production build everything: `yarn build`

# Using Mapwatch in your programs

See https://github.com/mapwatch/mapwatch/issues/13 - if you'd like to see this, let's talk! Mapwatch is in Elm, so your program would need to run Javascript or Elm to embed Mapwatch.

# Resources

[Analytics: recent referral traffic (you probably don't have permissions)](https://analytics.google.com/analytics/web/#/report/trafficsources-referrals/a119582500w176920100p175689790/_u.dateOption=last7days&explorer-table.secSegmentId=analytics.fullReferrer&explorer-table.plotKeys=%5B%5D&explorer-graphOptions.primaryConcept=analytics.totalVisitors&explorer-graphOptions.compareConcept=analytics.newVisits&_.useg=builtin1/)
