module main

import os
import term
import args

fn init_pkginfo_json(mode string) {
    pkg_name := os.filename(os.getwd())
    
    mut pkg_manifest_contents := []string
    mut manifest_filename := '.vpkg.json'

    switch mode {
        case 'vpkg':
            pkg_manifest_contents << '{\n   "name": "${pkg_name}",\n'
            pkg_manifest_contents << '   "version": "1.0"\n'
            pkg_manifest_contents << '   "author": ["Author Name <author@example.com>"],\n'
            pkg_manifest_contents << '   "repo": "https://github.com/username/repo",\n'
            pkg_manifest_contents << '   "dependencies": []\n'
            pkg_manifest_contents << '}' 
        case 'vmod':
            manifest_filename = 'v.mod'
            pkg_manifest_contents << 'Module {\n   name: \'${pkg_name}\',\n'
            pkg_manifest_contents << '   version: \'1.0\'\n'
            pkg_manifest_contents << '   dependencies: []\n'
            pkg_manifest_contents << '}' 
        default:
            pkg_manifest_contents << '{\n   "name": "${pkg_name}",\n'
            pkg_manifest_contents << '   "version": "1.0"\n'
            pkg_manifest_contents << '   "author": ["Author Name <author@example.com>"],\n'
            pkg_manifest_contents << '   "repo": "https://github.com/username/repo",\n'
            pkg_manifest_contents << '   "dependencies": []\n'
            pkg_manifest_contents << '}' 
    }

    manifest_data := os.create('${ModulesDir}/${manifest_filename}') or {
        eprintln('Package manifest file was not created successfully.')
        return
    }

    manifest_data.write(pkg_manifest_contents.join(''))
    defer { manifest_data.close() }

    println('Package manifest file was created successfully.')
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
        pkg_name := package_name(pkg.name)
        pkg_location := '${ModulesDir}/${pkg_name}'

        mut latest_hash := current_hash

        os.exec('git -C ${pkg_location} fetch')
        latest_hash = check_git_version(pkg_location)

        if current_hash != latest_hash {
            os.exec('git -C ${pkg_location} pull')

            updated_package := InstalledPackage{
                name: pkg.name,
                version: latest_hash
            }

            updated_packages << updated_package
        }
    }

    lockfile.regenerate(updated_packages, false)
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
    for dependency in pkg_info.dependencies {
        println('- ' + dependency)
    }

    println('\nInstalled packages:')

    for pkg in lockfile.packages {
        println('- ${pkg.name}@${pkg.version}')
    }
}

fn show_version() {
    println('VPkg ${Version} - ${os.user_os()}')
    println('Repo: https://github.com/v-pkg/vpkg \n')
    println('2019 (c) Ned Palacios and it\'s contributors.')
}

fn show_help() {
    println('VPkg ${Version}')
    println('An alternative package manager for V.')

    println('\nUSAGE\n')
    println('vpkg <COMMAND> [ARGS...] [options]')

    println('\nCOMMANDS\n')

    println('get [packages]                     Fetch and installs packages from the registry or the git repo.')
    println('help                               Prints this help message.')
    println('info                               Show project\'s package information.')
    println('init [--format=vpkg|vmod]          Creates a package manifest file into the current directory. Defaults to "vpkg".')
    println('install                            Reads the package manifest file and installs the necessary packages.')
    println('remove [packages]                  Removes packages')
    println('update                             Updates packages.')
    println('version                            Prints the Version of this program.')

    println('\nOPTIONS\n')
    println('--global, -g                       Installs the modules/packages into the `.vmodules` folder.')
}