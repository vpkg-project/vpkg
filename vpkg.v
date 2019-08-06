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
    mut found_pkg := false
    mut pkg := Package{'', '', ''}
    mut dl_pkg := InstalledPackage{'', '', ''}

    resp := http.get('https://v-pkg.github.io/registry/registry.json') or {
        eprintln('Cannot fetch from registry server')
        return dl_pkg
    }

    repo := json.decode(Registry, resp.text) or {
        eprintln('Failed to read repo.json')
        return dl_pkg
    }

    for i := 0; i < repo.packages.len; i++ {
        current_pkg := repo.packages[i]

        if current_pkg.name == name {
            found_pkg = true
            pkg = current_pkg
        }
    }

    if pkg.method == 'git' {
        dl_pkg = fetch_from_git(pkg.url, global)
    }

    return dl_pkg
}

fn fetch_from_git(path string, global bool) InstalledPackage {
    pkg_name := package_name(path)
    dir_name := if pkg_name.starts_with('v-') { pkg_name.all_after('v-') } else { pkg_name }
    install_location := if global { VLibDir } else { ModulesDir }
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
    exists_on_vlib := os.dir_exists('${VLibDir}/${pkg_name}')
    exists_on_cwd := os.dir_exists('${ModulesDir}/${pkg_name}')
    module_install_path := if exists_on_cwd && !global { ModulesDir } else { VLibDir }

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
        'install' => install_packages(is_global)
        'get' => get_packages(_argv.unknown, is_global)
        'remove' => remove_packages(_argv.unknown)
        'help' => show_help()
        'update' => update_packages()
        'info' => show_package_information()
        'version' => show_version()
        else => show_help()
    }
}
