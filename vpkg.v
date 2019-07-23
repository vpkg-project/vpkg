/*
* V Package Manager / vpkg
*/
module main

import http
import os
import json
import args
import term

const (
    Version = '0.1'
    VLibDir = '/root/code/v/vlib'
    ModulesDir = '${os.getwd()}'
    TmpDir = '${os.getwd()}/.tmp_vpkg'
)

fn fetch_from_registry(name string, global bool) DownloadedPackage {
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

    dl_pkg := fetch_from_git(pkg.name, global)

    return DownloadedPackage{
        name: dl_pkg.name,
        downloaded_path: dl_pkg.downloaded_path
    }
}

fn fetch_from_git(path string, global bool) DownloadedPackage {
    pkg_name := package_name(path)
    dir_name := if pkg_name.starts_with('v-') { pkg_name.all_after('v-') } else { pkg_name }
    install_location := if global { VLibDir } else { ModulesDir }
    clone_dir := '${install_location}/${dir_name}'

    os.exec('git clone ${path} ${clone_dir}')

    return DownloadedPackage{
        name: pkg_name,
        downloaded_path: clone_dir
    }
}

fn get_package(name string, global bool) DownloadedPackage {
    pkg_name := package_name(name)

    println('Fetching ${pkg_name}')
    exists_on_vlib := os.dir_exists('${VLibDir}/${pkg_name}')
    exists_on_cwd := os.dir_exists('${ModulesDir}/${pkg_name}')
    module_install_path := if exists_on_cwd { ModulesDir } else { VLibDir }

    mut data := DownloadedPackage{}

    if exists_on_vlib || exists_on_cwd {
        println('${pkg_name} is already installed.')

        data = DownloadedPackage{
            name: pkg_name,
            downloaded_path: '${module_install_path}/${pkg_name}'
        }
    }

    if is_git_url(name) {
        data = fetch_from_git(name, global)
    } else {
        println('coming from registry')
        data = fetch_from_registry(name, global)
    }

    return data
}


fn main() {
    _argv := args.parse(os.args, 1)
    
    is_global := if _argv.options.exists('g') || _argv.options.exists('global') {
        true
    } else {
        false
    }

    match _argv.command {
        'install' => install_packages(is_global)
        'get' => get_packages(_argv.unknown, is_global)
        'remove' => remove_packages(_argv.unknown)
        'help' => show_help()
        'version' => show_version()
        else => show_help()
    }
}