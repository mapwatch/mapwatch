import { negotiateLanguages } from "@fluent/langneg";
import { FluentResource, FluentBundle } from "@fluent/bundle";

import en_us from "!!raw-loader!./en-us.ftl.properties";
import test from "!!raw-loader!./test.ftl.properties";

function addResource(bundle, resource) {
  const errors = bundle.addResource(resource);
  if (errors.length) {
    throw errors[0];
  }
}

const DURATION = ([d], kwargs) => d + "";
const PERCENT = ([p], kwargs) => (p * 100 + "").substr(0, 5) + "%";
const PERCENT_INT = ([p], kwargs) => Math.floor(p * 100) + "" + "%";
const functions = {
  DURATION,
  PERCENT,
  PERCENT_INT,
};
const _bundles = {
  en_us: new FluentBundle("en-US", { functions }),
  test: new FluentBundle("test", { functions }),
};
addResource(_bundles.en_us, new FluentResource(en_us));
addResource(_bundles.test, new FluentResource(test));

export const bundles = [];
const availableLocales = [];
for (let bundle of Object.values(_bundles)) {
  for (let locale of bundle.locales) {
    bundles.push([locale, bundle]);
    availableLocales.push(locale);
  }
}

export const defaultLocales = negotiateLanguages(
  navigator.languages,
  availableLocales,
  { defaultLocale: "en-US" }
);

export function main(app, settings) {
  let liveTranslation = settings.readDefault({}).liveTranslation || "";
  if (!!liveTranslation) {
    pushLiveTranslation(app, liveTranslation);
  }
  app.ports.sendSettings.subscribe((s) => {
    const nextTranslation = (s || {}).liveTranslation || "";
    if (nextTranslation !== liveTranslation) {
      liveTranslation = nextTranslation;
      pushLiveTranslation(app, liveTranslation);
    }
  });
}
function pushLiveTranslation(app, liveTranslation) {
  let bundle = null;
  if (liveTranslation != null) {
    bundle = new FluentBundle("liveTranslation", { functions });
    const errors = bundle.addResource(new FluentResource(liveTranslation));
    if (errors.length) {
      throw errors[0];
    }
  }
  const provider = document.getElementsByTagName("fluent-provider")[0];
  if (provider) {
    // provider.bundles = Array.from(provider.bundles).concat([bundle])
    provider.bundles = [bundle];
    console.log(provider);
  }
  //app.ports.debugApplyLiveTranslation.send(bundle)
}
