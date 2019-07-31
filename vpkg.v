module main

import args
import os
import http
import json
import term

const (
    Version = '0.1'
    VLibDir = '/root/code/v/vlib'
    ModulesDir = '${os.getwd()}/modules'
    TmpDir = '${os.getwd()}/.tmp_vpkg'
    LockfilePath = '${os.getwd()}/.vpkg-lock.json'
)

fn fetch_from_registry(name string, global bool) InstalledPackage {
    resp := http.get('http://localhost:8080/registry.json') or {
        eprintln('Cannot fetch from registry server')
        return InstalledPackage{}
    }

    repo := json.decode([]Package, resp) or {
        eprintln('Failed to read repo.json')
        return InstalledPackage{}
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

    return dl_pkg
}

fn fetch_from_git(path string, global bool) InstalledPackage {
    pkg_name := package_name(path)
    dir_name := if pkg_name.starts_with('v-') { pkg_name.all_after('v-') } else { pkg_name }
    install_location := if global { VLibDir } else { ModulesDir }
    clone_dir := '${install_location}/${dir_name}'

    os.exec('git clone ${path} ${clone_dir}')

    return InstalledPackage{
        name: pkg_name,
        path: clone_dir,
        version: check_git_version(clone_dir)
    }
}

fn get_package(name string, global bool) InstalledPackage {
    pkg_name := package_name(name)

    println('Fetching ${pkg_name}')
    exists_on_vlib := os.dir_exists('${VLibDir}/${pkg_name}')
    exists_on_cwd := os.dir_exists('${ModulesDir}/${pkg_name}')
    module_install_path := if exists_on_cwd { ModulesDir } else { VLibDir }

    mut data := InstalledPackage{}

    if exists_on_vlib || exists_on_cwd {
        println('${pkg_name} is already installed.')
        installed_path := '${module_install_path}/${pkg_name}'
        data = InstalledPackage{
            name: pkg_name,
            path: installed_path,
            version: check_git_version(installed_path)
        }
    }

    data = if is_git_url(name) {
        fetch_from_git(name, global)
    } else {
        fetch_from_registry(name, global)
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