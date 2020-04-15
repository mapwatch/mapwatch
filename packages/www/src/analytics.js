window.dataLayer = window.dataLayer || [];
function gtag(){dataLayer.push(arguments);}
gtag('js', new Date());
gtag('set', 'transport', 'beacon');
gtag('config', 'UA-119582500-1', {'anonymize_ip': true});

function gaEvent(action, props) {
  // because I keep messing these two up, but analytics shouldn't break prod
  if (props.category) console.warn('ports.gaEvent: category should be event_category. '+JSON.stringify(props))
  if (props.label) console.warn('ports.gaEvent: label should be event_label. '+JSON.stringify(props))

  // console.log('gaEvent', action, props)
  gtag('event', action, props)
}
var gaDimensions = {
  // https://support.google.com/analytics/answer/2709829?hl=en#
  websiteVersion: 'dimension1',
  backend: 'dimension2',
  electronVersion: 'dimension3',
}
module.exports.main = function main (app, args) {
  gtag('set', gaDimensions.websiteVersion, args.websiteVersion);
  gtag('set', gaDimensions.backend, args.backend)
  gtag('set', gaDimensions.electronVersion, args.electronVersion);
  var isWatching = false
  var historyStats = {instanceJoins: 0, mapRuns: 0}
  app.ports.events.subscribe(function(event) {
    if (event.type === 'progressComplete') {
      if (!isWatching) {
        if (event.name === 'history' || event.name === 'history:example') {
          gaEvent('completed', {event_category: event.name})
          gaEvent('completed_stats', {event_category: event.name, event_label: 'instanceJoins', value: historyStats.instanceJoins})
          gaEvent('completed_stats', {event_category: event.name, event_label: 'mapRuns', value: historyStats.mapRuns})
          isWatching = true
        }
      }
    }
    else if (event.type === 'joinInstance') {
      if (!isWatching) {
        historyStats.instanceJoins += 1
        if (event.lastMapRun) {
          historyStats.mapRuns += 1
        }
      }
      else {
        gaEvent('join', {event_category: 'Instance', event_label: event.instance ? event.instance.zone : "MainMenu"})
        if (event.lastMapRun) {
          gaEvent('finish', {
            event_category: 'MapRun',
            event_label: event.lastMapRun.instance.zone,
            value: Math.floor((event.lastMapRun.leftAt - event.lastMapRun.joinedAt)/1000),
          })
        }
      }
    }
  })
}
