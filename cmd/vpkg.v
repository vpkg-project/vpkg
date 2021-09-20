module main

import cli
import api
import os

fn show_version() {
    println('vpkg ${api.meta.version} for ${os.user_os()}')
    println('Repo: https://github.com/vpkg-project/vpkg \n')
    println('2020-2021 (c) vpkg developers and it\'s contributors.')
}

fn main() {
    mut cmd := cli.Command{
        name: 'vpkg',
        description: api.meta.description,
        version: api.meta.version,
        parent: 0
    }

    global_flag := cli.Flag{
        flag: .bool,
        name: 'global',
        description: 'Install/remove the modules into/from the ".vmodules" folder.',
        value: ['false'],
        abbrev: 'g'
    }

    cmd.add_commands([
        cli.Command{
            name: 'get',
            description: 'Fetch and installs packages from the registry or directly from the version control.'
            flags: [global_flag]
            disable_help: false
            required_args: 1
            execute: fn (cmd cli.Command) ? {
                global := cmd.flags.get_bool('global') or { false }
                mut vpkg := api.new(if !global { os.getwd() } else { os.vmodules_dir() })
                installed_packages := vpkg.get_packages(cmd.args, {
                    force: cmd.flags.get_bool('force') or { false }
                }) ?

                println(installed_packages)
            }
        },
        cli.Command{
            name: 'info',
            description: 'Show project\'s package information.'
            execute: fn (cmd cli.Command) ? {
                mut vpkg := api.new(os.getwd())
                vpkg.print_info() ?
            }
        },
        cli.Command{
            name: 'init',
            description: 'Create a package manifest file into the current directory.'
            execute: fn (cmd cli.Command) ? {
                // current_dir := os.getwd()
                // api.get_packages(current_dir)
            }
        },
        cli.Command{
            name: 'install',
            description: 'Read the package manifest file and isntalls the necessary packages.'
            execute: fn (cmd cli.Command) ? {
                global := cmd.flags.get_bool('global') or { false }
                mut vpkg := api.new(if !global { os.getwd() } else { os.vmodules_dir() })
                installed_packages := vpkg.get_packages(vpkg.manifest.dependencies, {
                    force: cmd.flags.get_bool('force') or { false }
                }) ?
            }
        },
        cli.Command{
            name: 'migrate',
            description: 'Migrate existing manifest files to the v.mod format.'
        },
        cli.Command{
            name: 'release',
            description: 'Release a new version of the module.',
        },
        cli.Command{
            name: 'remove',
            description: 'Remove packages.',
            flags: [global_flag],
            required_args: 1,
            execute: fn (cmd cli.Command) ? {
                global := cmd.flags.get_bool('global') or { false }
                mut vpkg := api.new(if !global { os.getwd() } else { os.vmodules_dir() })
                removed_packages := vpkg.remove_packages(cmd.args) ?

            }
        },
        cli.Command{
            name: 'update',
            description: 'Update the packages.',
            flags: [global_flag],
            execute: fn (cmd cli.Command) ? {
                global := cmd.flags.get_bool('global') or { false }
                mut vpkg := api.new(if !global { os.getwd() } else { os.vmodules_dir() })
                updated_packages := vpkg.get_packages(vpkg.manifest.dependencies, {
                    force: cmd.flags.get_bool('force') or { false }
                    update: true
                }) ?
            }
        }
    ])

    cmd.parse(os.args)
}
