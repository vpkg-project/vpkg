module main

import args
import os
import http
import json
import term

const (
    Version = '0.2'
    GlobalModulesDir = '${os.home_dir()}/.vmodules'
    ModulesDir = '${os.getwd()}'
    TmpDir = '${os.getwd()}/.tmp_vpkg'
    LockfilePath = '${os.getwd()}/.vpkg-lock.json'
)

fn search_from_vpm(name string) Package {
    println('Searching package on VPM...')

    resp := http.get('https://vpm.best/jsmod/${name}') or {
        eprintln('Cannot fetch from VPM')
        return Package{}
    }

    repo := json.decode(VpmPackage, resp.text) or {
        eprintln('Failed to read repo.json')
        return Package{}
    }


    return Package{
        name: repo.name,
        url: repo.url,
        method: if is_git_url(repo.url) { 'git' } else { 'http' }
    }
}

fn search_from_registry(name string) Package {
    print('Searching package on registry...')

    resp := http.get('https://v-pkg.github.io/registry/registry.json') or {
        eprintln('Cannot fetch from registry server')
        return Package{}
    }

    repo := json.decode(Registry, resp.text) or {
        eprintln('Failed to read repo.json')
        return Package{}
    }

    for current_pkg in repo.packages {
        if current_pkg.name == name {
            return current_pkg
        }
    }

    return Package{}
}

fn fetch_from_registry(name string, global bool) InstalledPackage {
    mut pkg := Package{}
    mut dl_pkg := InstalledPackage{}

    // search first in vpm
    pkg = search_from_vpm(name)


    // if nothing found
    if pkg.name.len == 0 {
        pkg = search_from_registry(name)
    }

    if pkg.method == 'git' {
        dl_pkg = fetch_from_git(pkg.url, global)
    }

    return dl_pkg
}

fn fetch_from_git(path string, global bool) InstalledPackage {
    pkg_name := package_name(path)
    dir_name := if pkg_name.starts_with('v-') { pkg_name.all_after('v-') } else { pkg_name }
    install_location := if global { GlobalModulesDir } else { ModulesDir }
    clone_dir := '${install_location}/${dir_name}'

    os.exec('git clone ${path} ${clone_dir} --branch master  --depth 1')

    return InstalledPackage{
        name: pkg_name,
        path: clone_dir,
        version: check_git_version(clone_dir)
    }
}

fn get_package(name string, global bool) InstalledPackage {
    pkg_name := package_name(name)

    println('Fetching ${pkg_name}')
    exists_on_vlib := os.dir_exists('${GlobalModulesDir}/${pkg_name}')
    exists_on_cwd := os.dir_exists('${ModulesDir}/${pkg_name}')
    module_install_path := if exists_on_cwd && !global { ModulesDir } else { GlobalModulesDir }

    mut data := InstalledPackage{}

    if (exists_on_vlib && global) || exists_on_cwd {
        installed_path := '${module_install_path}/${pkg_name}'

        println('${name} is already installed.')
        
        data = InstalledPackage{
            name: name,
            path: '${module_install_path}/${pkg_name}',
            version: check_git_version(installed_path)
        }
    } else {
        if is_git_url(name) {
            data = fetch_from_git(name, global)
        } else {
            data = fetch_from_registry(name, global)
        }
    }

    return data
}


fn main() {
    _argv := args.parse(os.args, 1)
    
    is_global := if 'g' in _argv.options || 'global' in _argv.options {
        true
    } else {
        false
    }

    match _argv.command {
        'get' => get_packages(_argv.unknown, is_global)
        'help' => show_help()
        'info' => show_package_information()
        'init' => init_pkginfo_json()
        'install' => install_packages(is_global)
        'remove' => remove_packages(_argv.unknown)
        'update' => update_packages()
        'version' => show_version()
        else => show_help()
    }
}
