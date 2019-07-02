/*
* V Package Manager / vpkg
*/

import http
import os
import json
import args
import term

const (
    VERSION = '0.1'
    VLIB_PATH = '/root/code/v/vlib'
    TMP_DIR = '${os.getwd()}/.vpkg_tmp'
)

struct Package {
    name string
    url string
}

struct DownloadedPackage {
    name string
    downloaded_path string
}

struct PkgInfo {
    name string
    version string
    repo string
    packages []string
}

fn package_name(name string) string {
    mut is_git := is_git_url(name)
    mut pkg_name := name

    if is_git {
        pkg_name = os.filename(name)
    }

    if is_git && name.contains('.git') {
        pkg_name = pkg_name.replace('.git', '')
    }

    return pkg_name
}

fn fetch_from_registry(name string) DownloadedPackage {
    resp := http.get('http://localhost:8080/registry.json')
    repo := json.decode([]Package, resp) or {
        eprintln('Failed to read repo.json')
        return DownloadedPackage {
            name: name,
            downloaded_path: ''
        }
    }
    mut found_pkg := false
    mut pkg_index := 0
    mut pkg := Package{}

    for i := 0; i < repo.len; i++ {
        current_pkg := repo[i]

        if current_pkg.name == name {
            found_pkg = true
            pkg_index = i
            pkg = repo[pkg_index]
        }
    }

    dl_pkg := fetch_from_git(pkg.name)

    return DownloadedPackage{
        name: dl_pkg.name,
        downloaded_path: dl_pkg.downloaded_path
    }
}

fn fetch_from_git(path string) DownloadedPackage {
    mut pkg_name := package_name(path)

    os.exec('git clone ${path} ${TMP_DIR}/${pkg_name}')

    return DownloadedPackage{
        name: pkg_name,
        downloaded_path: '${TMP_DIR}/${pkg_name}'
    }
}

fn is_git_url(a string) bool {
    return a.starts_with('https://') || a.starts_with('git://')
}

fn copy_packages_to_vlib(downloaded_packages []DownloadedPackage) int {
    for package in downloaded_packages {
        println('Copying ${package.name}')
        os.mv('${package.downloaded_path}', '${VLIB_PATH}/${package.name}')
        println('to ${VLIB_PATH}/${package.name}')
    }

    // TODO: When os.rmdir is implemented
    // os.rmdir(TMP_DIR)
    return 1
}

fn get_package(name string) DownloadedPackage {
    println('Fetching ${package_name(name)}')

    if (os.dir_exists('${VLIB_PATH/${package_name(name)}')) {
        println('${package_name(name)} is already installed.')

        return DownloadedPackage {
            name: package_name(name),
            downloaded_path: '${VLIB_PATH/${package_name(name)}'
        }
    }

    if !os.dir_exists(TMP_DIR) {
        os.mkdir(TMP_DIR)    
    }

    if is_git_url(name) {
        return fetch_from_git(name)
    } else {
        return fetch_from_registry(name)
    }
}

fn install_packages() {
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
        pkg := get_package(package)
        packages << pkg
    }

    copy_packages_to_vlib(packages)

    return
}

fn show_version() {
    println('vpkg ${VERSION}')
    println(os.user_os())
}

fn show_help() {
    println('VPkg ${VERSION}')
    println('Just a toy package manager for V.')

    println('COMMANDS')

    println('get [package name / git url] - Fetch packages from the registry or the git repo.')
    println('install - reads the ".vpkg.json" file and installs the necessary packages.')
    println('help - Prints this help message.')
    println('version - Prints the version of this program.')
}

fn main() {
    _argv := args.parse(os.args)

    switch _argv.command {
        case 'install':
            install_packages()
        case 'get':
            package := get_package(_argv.unknown[0])
            copy_packages_to_vlib([package])
        case 'help':
            show_help()
        case 'version':
            show_version()
    }
}