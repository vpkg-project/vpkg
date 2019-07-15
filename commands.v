module main

import os
import term
import args

fn install_packages(global bool) {
    mut packages := []DownloadedPackage

    vpkg_file := os.read_file('${os.getwd()}/.vpkg.json') or {
        eprintln(term.red('No .vpkg.json found.'))
        return
    }

    pkg_info := json.decode(PkgInfo, vpkg_file) or {
        eprintln(term.red('Error decoding .vpkg.json'))
        return
    }

    println('Installing packages')
    for package in pkg_info.packages {
        pkg := get_package(package, global)
        packages << pkg
    }

    return
}

fn remove_packages(packages []string) {
    // TODO: Remove packages
}

fn update_packages() {
    // TODO: Update packages
}

fn get_packages(packages []string, global bool) []DownloadedPackage {
    mut installed_packages := []DownloadedPackage

    for i := 0; i < packages.len; i++ {
        package := get_package(packages[i], global)

        installed_packages << package
    }

    return installed_packages
}

fn show_version() {
    println('vpkg ${Version}')
    println(os.user_os())
}

fn show_help() {
    println('VPkg ${Version}')
    println('Just another package manager for V.')

    println('\nCOMMANDS\n')

    println('get [packages]                     Fetch packages from the registry or the git repo.')
    println('install                            reads the ".vpkg.json" file and installs the necessary packages.')
    println('help                               Prints this help message.')
    println('version                            Prints the Version of this program.')

    println('\nOPTIONS\n')
    println('--global, -g                       Installs the modules/packages into the vlib folder.')
}