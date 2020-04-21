import { negotiateLanguages } from '@fluent/langneg'
import {FluentResource, FluentBundle} from '@fluent/bundle'

import en_us from '!!raw-loader!./en-us.ftl.properties'
import test from '!!raw-loader!./test.ftl.properties'

function addResource(bundle, resource) {
  const errors = bundle.addResource(resource)
  if (errors.length) {
    throw errors[0]
  }
}

const DURATION = ([d], kwargs) => d+''
const PERCENT = ([p], kwargs) => (p * 100 + '').substr(0, 5) + '%'
const PERCENT_INT = ([p], kwargs) => (Math.floor(p * 100) + '') + '%'
const bundles = {
  en_us: new FluentBundle('en-US', {
    functions: {
      DURATION,
      PERCENT,
      PERCENT_INT,
    },
  }),
  test: new FluentBundle('test', {
    functions: {
      DURATION,
      PERCENT,
      PERCENT_INT,
    },
  }),
}
addResource(bundles.en_us, new FluentResource(en_us))
addResource(bundles.test, new FluentResource(test))

const bundlesByLocale = []
const availableLocales = []
for (let bundle of Object.values(bundles)) {
  for (let locale of bundle.locales) {
    bundlesByLocale.push([locale, bundle])
    availableLocales.push(locale)
  }
}

const defaultLocales = negotiateLanguages(
  navigator.languages,
  availableLocales,
  {defaultLocale: 'en-US'},
)
console.log('defaultLocales', {defaultLocales, availableLocales, bundlesByLocale})
export default {defaultLocales, bundles: bundlesByLocale}
