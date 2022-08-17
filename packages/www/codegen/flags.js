const fs = require('fs/promises')
const path = require('path')
const datamine = require('../src/datamine')

const EXAMPLES_DIR = path.normalize(`${__dirname}/../public/examples`)

async function main() {
    const filenames = await fs.readdir(EXAMPLES_DIR)
    const examples = await Promise.all(filenames.map(async file => {
        const slug = file.replace(/\.txt$/, '').replace('-', '_')
        const path = `${EXAMPLES_DIR}/${file}`
        const buf = await fs.readFile(path)
        const body = buf.toString()
        // return {file, path, slug, body}
        return {file, slug, body}
    }))
    console.log(JSON.stringify({examples, datamine}, null, 2))
}

main().catch(err => {
    console.error(err)
    process.exit(1)
})