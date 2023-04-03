const fs = require('fs/promises')

async function main() {
    return await Promise.all([buildExamples(), buildJson(), buildExampleOfSize('big.txt', 45)])
}
const EXAMPLES_DIR = `${__dirname}/../../public/examples`
async function buildExamples() {
    const filenames = await fs.readdir(EXAMPLES_DIR)
    const examples = await Promise.all(filenames.filter(f => f !== 'big.txt' || f.startsWith('.')).map(async file => {
        const slug = file.replace(/\.txt$/, '').replace(/-/g, '_')
        const path = `${EXAMPLES_DIR}/${file}`
        const buf = await fs.readFile(path)
        const body = buf.toString()
        return {file, path, slug, body}
    }))

    return fs.writeFile(__dirname+'/Examples.elm',
    `module Fixture.Examples exposing (Example, list_, ${examples.map(e => e.slug).join(', ')})

type alias Example = {file: String, slug: String, body: String}

list_ : List Example
list_ =
    [ ${examples.map(ex => `{file=${JSON.stringify(ex.file)}, slug=${JSON.stringify(ex.slug)}, body=${ex.slug}}\n`).join("    , ")}    ]

${examples.map(ex => `
{-| ${ex.file}

    ${ex.path}
-}
${ex.slug} : String
${ex.slug} = ${JSON.stringify(ex.body)}
`.trim()
    ).join("\n\n")}
`)
}

async function buildJson() {
    return fs.writeFile(__dirname+'/Json.elm',
    `module Fixture.Json exposing (datamine)

datamine : String
datamine = ${JSON.stringify(JSON.stringify(require('../../src/datamine.js')))}
`)
}

function range(n) {
    return [...Array(n).keys()]
}
function pad0(val, n) {
    return val.toString().padStart(n, '0')
}
async function buildExampleOfSize(name, mb) {
    return fs.writeFile(`${__dirname}/../../public/examples/${name}`, range(mb).map(i => {
        const s = `# entry #${i}
2023/04/03 00:${pad0(i, 2)}:00 157224625 d8 [INFO Client 1012] Connecting to instance server at 0.0.0.${i}:6112
2023/04/03 00:${pad0(i, 2)}:00 157183906 9b0 [INFO Client 1012] : You have entered Enlightened Hideout.
2023/04/03 00:${pad0(i, 2)}:01 157224625 d8 [INFO Client 1012] Connecting to instance server at 0.0.1.${i}:6112
2023/04/03 00:${pad0(i, 2)}:01 157234265 9b0 [INFO Client 1012] : You have entered Toxic Sewer.
2023/04/03 00:${pad0(i, 2)}:02 157224625 d8 [INFO Client 1012] Connecting to instance server at 0.0.0.${i}:6112
2023/04/03 00:${pad0(i, 2)}:02 157183906 9b0 [INFO Client 1012] : You have entered Enlightened Hideout.
# 1mb of padding: `
        return s.padEnd(Math.pow(2, 20) - s.length - 1, '#')
    }).join("\n"))
}

main().catch(err => {
    console.error(err)
    process.exit(1)
})