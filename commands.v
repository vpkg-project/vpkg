module main

import os
import term
import args

fn install_packages(global bool) {
    vpkg_file := os.read_file('${os.getwd()}/.vpkg.json') or {
        eprintln(term.red('No .vpkg.json found.'))
        return
    }

    pkg_info := json.decode(PkgInfo, vpkg_file) or {
        eprintln(term.red('Error decoding .vpkg.json'))
        return
    }

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
// fn update_packages() {
//     // readlockfile
//     installed_packages := os.ls(ModulesDir)
//     println('Updating packages')

//     for package in installed_packages {
//         current_hash := os.exec('git log --pretty=format:\'%h\' -n 1')
//         mut latest_hash := current_hash

//         os.exec('git fetch')
//         latest_hash = os.exec('git log --pretty=format:\'%h\' -n 1')

//         if current_hash != latest_hash {
//             os.exec('git pull')
//         }
//     }
// }

fn get_packages(packages []string, global bool) {
    mut installed_packages := []DownloadedPackage

    for i := 0; i < packages.len; i++ {
        package := get_package(packages[i], global)

        installed_packages << package
    }

    println('${installed_packages.len} packages were installed successfully.')
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