## Contributing to Mapwatch

Happy to consider pull requests. Talk to @erosson before spending lots of time on one - accepting pull requests is not a sure thing, even when there's an open issue.

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

# Release

The website is automatically built and deployed on release by [Travis-CI](https://travis-ci.org/github/mapwatch/mapwatch). [CI configuration](https://github.com/mapwatch/mapwatch/blob/master/.travis.yml).

The downloadable Electron app is a little more complex, and is not automated: https://www.electron.build/configuration/publish#recommended-github-releases-workflow

* [Create a *draft* release](https://github.com/mapwatch/mapwatch/releases). No tag. Name it after the next version number.
* Commit some stuff. CI will add its files to the draft release created above.
* When ready, click "publish" on your draft release. Can't change it afterward.

# Resources

[Analytics: recent referral traffic (you probably don't have permissions)](https://analytics.google.com/analytics/web/#/report/trafficsources-referrals/a119582500w176920100p175689790/_u.dateOption=last7days&explorer-table.secSegmentId=analytics.fullReferrer&explorer-table.plotKeys=%5B%5D&explorer-graphOptions.primaryConcept=analytics.totalVisitors&explorer-graphOptions.compareConcept=analytics.newVisits&_.useg=builtin1/)
