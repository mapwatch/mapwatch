/**
 * Run poe-dat-viewer (pdv) with a specified poe-version + config + output dir. Loads poe dat files.
 */
import * as fs from 'fs/promises'
import minimist from 'minimist'
import util from 'util'
import * as child_process from 'child_process'

interface Args {
  version: string
  config: string
  output: string
}
const PDV_LIB = `${__dirname}/../third-party/poe-dat-viewer/lib`

function parse(): Args {
    const args = minimist(process.argv.slice(2))
    if (!args.version) throw new Error('--version required')
    if (!args.config) throw new Error('--config required')
    if (!args.output) throw new Error('--output required')
    return {version: args.version, config: args.config, output: args.output}
}
async function writeConfig(args: Args) {
  const buf = await fs.readFile(args.config)
  const config = JSON.parse(buf.toString())
  config.patch = args.version
  await fs.writeFile(`${PDV_LIB}/config.json`, JSON.stringify(config, null, 2))
}

async function main() {
    const args = parse()
    await writeConfig(args)
    await fs.rm(`${PDV_LIB}/tables`, {recursive: true, force: true})
    const {stdout, stderr} = await util.promisify(child_process.exec)(`node ${PDV_LIB}/src/cli.js`, {cwd: PDV_LIB})
    console.log(stdout, stderr)
    await fs.mkdir(`${args.output}/..`, {recursive: true})
    await fs.rename(`${PDV_LIB}/tables`, args.output)
}
main().catch(err => {
    console.error(err)
    process.exit(1)
})