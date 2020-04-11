function parseQS(location) {
  return {..._parseQS(location.search), ..._parseQS(location.hash)}
}
function _parseQS(search) {
  var qs = (search||'').split('?')[1]
  var pairs = (qs||'').split('&').filter(i => !!i)
  var ret = {}
  for (var i=0; i<pairs.length; i++) {
    var pair = pairs[i].split('=')
    ret[decodeURIComponent(pair[0])] = decodeURIComponent(pair[1])
  }
  return ret
}
module.exports = {parseQS}
