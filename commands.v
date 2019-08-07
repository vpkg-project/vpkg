module main

import os
import term
import args

fn init_pkginfo_json() {
    mut vpkg_json_contents := ['{', '\n']

    vpkg_json_contents << '   "name": "${Version}",\n'
    vpkg_json_contents << '   "version": "1.0"\n'
    vpkg_json_contents << '   "author": ["Author Name <author@example.com>"],\n'
    vpkg_json_contents << '   "repo": "https://github.com/username/repo",\n'
    vpkg_json_contents << '   "dependencies": []\n'
    vpkg_json_contents << '}'

    vpkg_json := os.create('${ModulesDir}/.vpkg.json') or {
        eprintln('.vpkg.json file was not created successfully.')
        return
    }
    
    vpkg_json.write(vpkg_json_contents.join(''))
    defer { vpkg_json.close() }

    println('.vpkg.json file was create successfully.')
}

fn install_packages(global bool) {
    pkg_info := load_package_file() or {
        return
    }

    println('Installing packages')
    packages := pkg_info.dependencies

    get_packages(packages, global)
}

fn remove_packages(packages []string) {
    mut removed_packages := []InstalledPackage
    mut lockfile := read_lockfile() or {
        println(err)
        return
    }

    for package in packages {
        pkg_name := if package.starts_with('v-') { package.all_after('v-') } else { package }
        status := delete_package_contents('${ModulesDir}/${pkg_name}')

        if status {
            removed_packages << InstalledPackage{
                name: package
            }
        }
    }

    lockfile.regenerate(removed_packages, true)

    print_status(removed_packages, 'removed')
}

// TODO: Update packages
fn update_packages() {    
    mut updated_packages := []InstalledPackage

    println('Fetching lockfile')
    mut lockfile := read_lockfile() or {
        println(err)
        create_lockfile()
        return
    }

    println('Updating packages')

    for pkg in lockfile.packages {
        current_hash := pkg.version
        mut latest_hash := current_hash

        os.exec('git --git-dir ${pkg.path}/.git fetch')
        latest_hash = check_git_version(pkg.path)

        if current_hash != latest_hash {
            os.exec('git --git-dir ${pkg.path}/.git pull')

            updated_package := InstalledPackage{
                name: pkg.name,
                path: pkg.path,
                version: latest_hash
            }

            updated_packages << updated_package
        }
    }

    lockfile.regenerate(updated_packages, false)

    for package in updated_packages {
        println('${package.name}@${package.version}')
    }

    print_status(updated_packages, 'updated')
}

fn get_packages(packages []string, global bool) {
    mut installed_packages := []InstalledPackage
    mut lockfile := read_lockfile() or {
        println(err)
        create_lockfile()
        return
    }

    for i := 0; i < packages.len; i++ {
        package := get_package(packages[i], global)

        if package.name.len != 0 {
            installed_packages << package
        }
    }

    lockfile.regenerate(installed_packages, false)

    for package in installed_packages {
        println('${package.name}@${package.version}')
    }

    print_status(installed_packages, 'installed')
}

fn show_package_information() {
    pkg_info := load_package_file() or {
        return
    }

    lockfile := read_lockfile() or {
        println(err)
        create_lockfile()
        return
    }

    println('Package name: ${pkg_info.name}@${pkg_info.version}')
    println('\nDependencies:')
    for i := 0; i < pkg_info.dependencies.len; i++ {
        println('- ' + pkg_info.dependencies[i])
    }

    println('\nInstalled packages:')

    for i := 0; i < lockfile.packages.len; i++ {
        pkg := lockfile.packages[i]

        println('- ${pkg.name}@${pkg.version}')
    }
}

fn show_version() {
    println('vpkg ${Version}')
    println(os.user_os())
}

fn show_help() {
    println('VPkg ${Version}')
    println('An alternative package manager for V.')

    println('\nCOMMANDS\n')

    println('get [packages]                     Fetch and installs packages from the registry or the git repo.')
    println('help                               Prints this help message.')
    println('info                               Show project\'s package information.')
    println('init                               Create a ".vpkg.json" manifest file into the current directory.')
    println('install                            Reads the ".vpkg.json" file and installs the necessary packages.')
    println('remove [packages]                  Removes packages')
    println('update                             Updates packages.')
    println('version                            Prints the Version of this program.')

    println('\nOPTIONS\n')
    println('--global, -g                       Installs the modules/packages into the vlib folder.')
}