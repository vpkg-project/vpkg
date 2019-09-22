module main

import (
    os
    net.urllib as urllib
)

fn fetch_from_registry(name string, install_location string, global bool, sources []string) InstalledPackage {
    mut pkg := Package{}
    mut dl_pkg := InstalledPackage{}

    for registry_url in sources {
        if registry_url == 'vpm' {
            println('Fetching package from ${registry_url}...')
        } else {
            url := urllib.parse(registry_url) or {
                return dl_pkg
            }
            println('Fetching package from ${url.host}...')
        }

        pkg = if registry_url == 'vpm' { 
            search_from_vpm(name)
        } else { 
            search_from_registry(name, registry_url)
        }

        if pkg.name.len == 0 {
            continue
        } else {
            break
        }
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
    clone_url := path.all_before('#')
    clone_dir := '${install_location}/${dir_name}'

    if os.dir_exists(clone_dir) {
        delete_package_contents(clone_dir)
    }

    git_clone := os.exec('git clone ${clone_url} ${clone_dir} --branch ${branch} --quiet --depth 1') or {
        eprintln('Git clone error')
        return InstalledPackage{}
    }

    println(git_clone.output)

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

    if (exists_on_vlib && vpkg.is_global) || (exists_on_cwd && !('force' in vpkg.options)) {
        installed_path := '${module_install_path}/${pkg_name}'

        println('${pkg_name} is already installed.')
        
        data = InstalledPackage{
            name: pkg_name,
            path: '${module_install_path}/${pkg_name}',
            version: check_git_version(installed_path)
        }
    } else {
        if is_git_url(name) {
            data = fetch_from_git(name, install_location, vpkg.is_global)
        } else {
            use_builtin := 'use-builtin' in vpkg.options
            mut sources := []string

            if !use_builtin || vpkg.options['use-builtin'] != 'false' {
                sources << ['vpm', 'https://v-pkg.github.io/registry/']
            }

            sources << vpkg.manifest.sources

            data = fetch_from_registry(name, install_location, vpkg.is_global, sources)
        }

        if data.name.len == 0 {
            println('Package \'${name}\' not found.')
        }
    }

    return data
}