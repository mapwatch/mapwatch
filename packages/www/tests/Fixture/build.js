const fs = require('fs/promises')

async function main() {
    return await Promise.all([buildExamples(), buildJson()])
}
const EXAMPLES_DIR = `${__dirname}/../../public/examples`
async function buildExamples() {
    const filenames = await fs.readdir(EXAMPLES_DIR)
    const examples = await Promise.all(filenames.map(async file => {
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

main().catch(err => {
    console.error(err)
    process.exit(1)
})