steampull
=========

[![push](https://github.com/erosson/steampull/workflows/push/badge.svg)](https://github.com/erosson/steampull/actions?query=workflow%3Apush)

Headlessly fetch game data from steam, if it's changed since we last ran.

Intended for continuous integration robots to run periodically, checking for game updates/patches.

Windows setup: `pip install steamctl wexpect`

Unix setup: `pip install steamctl pexpect`

Usage: `./steampull/steampull --help`
