import {FluentResource, FluentBundle} from '@fluent/bundle'

import en_us from '!!raw-loader!./en-us.ftl.properties'

function addResource(bundle, resource) {
  const errors = bundle.addResource(resource)
  if (errors.length) {
    throw errors[0]
  }
}

const PERCENT = ([p], kwargs) => (p * 100 + '').substr(0, 5) + '%'
const PERCENT_INT = ([p], kwargs) => (Math.floor(p * 100) + '') + '%'
export const bundles = {
  en_us: new FluentBundle('en-US', {
    functions: {
      DURATION: ([d], kwargs) => d+'',
      PERCENT,
      PERCENT_INT,
    },
  }),
}
addResource(bundles.en_us, new FluentResource(en_us))
export default [bundles.en_us]
