const fs = require('fs').promises

function guessPoePath() {
  return Promise.all([
    "C:\\Program Files (x86)\\Grinding Gear Games\\Path of Exile\\logs\\Client.txt",
    "C:\\Program Files\\Grinding Gear Games\\Path of Exile\\logs\\Client.txt",
    "C:\\Steam\\steamapps\\common\\Path of Exile\\logs\\Client.txt",
  ].map(path =>
    fs.access(path)
    .then(() => path)
    .catch(err => null)
  ))
  .then(paths => paths.filter(val => !!val))
  .then(paths => new Promise((resolve, reject) =>
      paths.length
        ? resolve(paths[0])
        : reject("Couldn't guess client.txt path")
  ))
}
guessPoePath().then(console.log, console.error)
