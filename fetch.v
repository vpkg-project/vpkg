module main

import os

fn fetch_from_registry(name string, install_location string, global bool) InstalledPackage {
    mut pkg := Package{}
    mut dl_pkg := InstalledPackage{}

    pkg = search_from_vpm(name)

    if pkg.name.len == 0 {
        pkg = search_from_registry(name)
    }

    if pkg.method == 'git' {
        dl_pkg = fetch_from_git(pkg.url, install_location, global)
    }

    return dl_pkg
}

fn fetch_from_git(path string, install_location string, global bool) InstalledPackage {
    pkg_name := package_name(path)
    dir_name := if pkg_name.starts_with('v-') { pkg_name.all_after('v-') } else { pkg_name }
    branch := if path.all_after('#') != path { path.all_after('#') } else { 'master' }
    clone_dir := '${install_location}/${dir_name}'

    cmd_output := os.exec('git clone ${path} ${clone_dir} --branch ${branch} --depth 1') or {
        eprintln('Git clone error')
        return InstalledPackage{}
    }

    println(cmd_output.output)

    return InstalledPackage{
        name: pkg_name,
        path: clone_dir,
        version: check_git_version(clone_dir)
    }
}

fn (vpkg mut Vpkg) get_package(name string) InstalledPackage {
    pkg_name := package_name(name)

    println('Fetching ${pkg_name}')
    exists_on_vlib := os.dir_exists('${GlobalModulesDir}/${pkg_name}')
    exists_on_cwd := os.dir_exists('${vpkg.dir}/${pkg_name}')
    module_install_path := if exists_on_cwd && !vpkg.is_global { vpkg.dir } else { GlobalModulesDir }
    install_location := if vpkg.is_global { GlobalModulesDir } else { vpkg.dir }

    mut data := InstalledPackage{}

    if (exists_on_vlib && vpkg.is_global) || exists_on_cwd {
        installed_path := '${module_install_path}/${pkg_name}'

        println('${name} is already installed.')
        
        data = InstalledPackage{
            name: name,
            path: '${module_install_path}/${pkg_name}',
            version: check_git_version(installed_path)
        }
    } else {
        if is_git_url(name) {
            data = fetch_from_git(name, install_location, vpkg.is_global)
        } else {
            data = fetch_from_registry(name, install_location, vpkg.is_global)
        }

        if data.name.len == 0 {
            println('Package \'${name}\' not found.')
        }
    }

    return data
}