module main

import os
import term
import args

fn install_packages(global bool) {
    pkg_info := load_package_file()

    println('Installing packages')
    packages := pkg_info.packages

    get_packages(packages, global)
}

fn remove_packages(packages []string) {
    mut removed_packages := []string

    for package in packages {
        pkg_name := if package.starts_with('v-') { package.all_after('v-') } else { package }
        status := delete_package_contents('${ModulesDir}/${pkg_name}')

        if status {
            removed_packages << package
        }
    }

    println('${removed_packages.len} packages were removed.')
}

// TODO: Update packages
fn update_packages() {    
    mut updated_packages := []InstalledPackage

    println('Fetching lockfile')
    mut lockfile := read_lockfile() or {
        create_lockfile()

        eprintln('Lockfile not found.')
        return
    }

    println('Updating packages')

    for name, pkg in lockfile.packages {
        current_hash := pkg.version
        mut latest_hash := current_hash

        os.exec('git --git-dir ${pkg.path}/.git fetch')
        latest_hash = check_git_version(pkg.path)

        if current_hash != latest_hash {
            os.exec('git --git-dir ${pkg.path}/.git pull')

            updated_package := InstalledPackage{
                name: name,
                path: pkg.path,
                version: latest_hash
            }

            updated_packages << updated_package
        }
    }

    lockfile.regenerate(updated_packages)

    for package in updated_packages {
        println('${package.name}@${package.version}')
    }

    println('${updated_packages.len} packages were updated successfully')
}

fn get_packages(packages []string, global bool) {
    mut installed_packages := []InstalledPackage
    mut lockfile := read_lockfile() or {
        create_lockfile()

        eprintln('Lockfile not found.')
        return
    }

    for i := 0; i < packages.len; i++ {
        package := get_package(packages[i], global)

        installed_packages << package
    }

    lockfile.regenerate(installed_packages)

    for package in installed_packages {
        println('${package.name}@${package.version}')
    }

    println('${installed_packages.len} packages were installed successfully.')
}

fn show_package_information() {
    pkg_info := load_package_file()

    println('Package name: ${pkg_info.name}')
}

fn show_version() {
    println('vpkg ${Version}')
    println(os.user_os())
}

fn show_help() {
    println('VPkg ${Version}')
    println('Just another package manager for V.')

    println('\nCOMMANDS\n')

    println('get [packages]                     Fetch and installs packages from the registry or the git repo.')
    println('install                            Reads the ".vpkg.json" file and installs the necessary packages.')
    println('remove [packages]                  Removes packages')
    println('help                               Prints this help message.')
    println('version                            Prints the Version of this program.')

    println('\nOPTIONS\n')
    println('--global, -g                       Installs the modules/packages into the vlib folder.')
}