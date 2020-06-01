// vpkg 0.7.1
// https://github.com/vpkg-project/vpkg
//
// Copyright (c) 2020 vpkg developers
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

module api

import os

pub fn (vpkg Vpkg) migrate_manifest() {
    m_type := if 'format' in vpkg.options { vpkg.options['format'] } else { 'vpkg' }

    migrate_manifest_file(vpkg.dir, vpkg.manifest, m_type)
}

pub fn (mut vpkg Vpkg) release_module_to_git() {
    if 'inc' in vpkg.options {
        state := if 'state' in vpkg.options { vpkg.options['state'] } else { '' }

        vpkg.manifest.version = vpkg.manifest.manipulate_version(vpkg.options['inc'], state)
        migrate_manifest_file(vpkg.dir, vpkg.manifest, identify_manifest_type(vpkg.manifest_file_path))
    }

    if vpkg.manifest.test_files.len != 0 {
        vpkg.test_package()
    }

    println('Releasing ${vpkg.manifest.name} ${vpkg.manifest.version}...')
    os.system('git tag -a v${vpkg.manifest.version}')
}

pub fn (vpkg Vpkg) test_package() {
    mut pwd_var := ''
    mut separator := '/'

    $if linux {
        pwd_var = '\$PWD'
        separator = '/'
    } $else {
        pwd_var = '%cd%'
        separator = '\\'
    }

    package_path := os.join_path(pwd_var, '..' + separator)
    package_name := dirname(os.getwd())
    mut files := []string{}

    if os.exists('${package_name}_test.v') {
        files << '${package_name}_test.v'
    }

    if 'files' in vpkg.options {
        files << vpkg.options['files'].split(',')
    }

    if vpkg.manifest.test_files.len != 0 {
        files << vpkg.manifest.test_files
    }

    for file in files {
        if !os.exists(file) {
            println('Test file/folder ${file} is not present.')
            return
        }
    }

    files_joined := files.join(' ')
    os.system('v -user_mod_path ${package_path} test ${files_joined}')

    for file in files {
        if os.is_dir(file) {
            folder_contents := os.ls(file) or { return }
            for f in folder_contents {
                rm_test_execs(os.join_path(file, f))
            }
        } else {
            rm_test_execs(file)
        }
    }
}

pub fn (vpkg Vpkg) create_manifest_file() {
    pkg_name := dirname(vpkg.dir)
    mut manifest_filename := 'vpkg.json'
    mut mw := new_vpkg_json()

    match vpkg.options['format'] {
        'vmod' {
            mw = new_vmod()
            manifest_filename = 'v.mod'
        }
        'vpkg' { mw = new_vpkg_json() }
        else {}
    }

    mw.write('name', pkg_name, false)
    mw.write('version', '1.0.0', false)

    if vpkg.options['format'] == 'vmod' {
        mw.write_arr('deps', [], false)
    } else {
        mw.write_arr('author', ['Your Author Name <author@example.com>'], false)
        mw.write('repo', 'https://github.com/<your-username>/<your-repo>', false)
        mw.write_arr('test_files', [], false)
        mw.write_arr('dependencies', [], false)
    }

    mw.close()

    mut manifest_data := os.create(os.join_path(vpkg.dir, manifest_filename)) or {
        eprintln('Package manifest file was not created successfully.')
        return
    }

    manifest_data.write(mw.contents.str())
    defer { manifest_data.close() }
    mw.contents.free()

    println('Package manifest file was created successfully.')
}

pub fn (mut vpkg Vpkg) install_packages(dir string) {
    println('Installing packages')
    pkg_info := vpkg.manifest
    packages := pkg_info.dependencies
    vpkg.get_packages(packages, true)
}

pub fn (vpkg Vpkg) remove_packages(packages []string) {
    mut removed_packages := []InstalledPackage{}
    mut lockfile := read_lockfile(vpkg.dir) or {
        println(err)
        return
    }

    for package in packages {
        pkg_name := if package.starts_with('v-') { package.all_after('v-') } else { package }
        status := delete_package_contents(os.join_path(vpkg.install_dir, pkg_name))

        if status { removed_packages << InstalledPackage{ name: package } }
    }

    lockfile.regenerate(removed_packages, true, vpkg.dir)
    print_status(removed_packages, 'removed')
}

pub fn (vpkg Vpkg) update_packages() {    
    mut updated_packages := []InstalledPackage{}
    println('Fetching lockfile')
    mut lockfile := read_lockfile(vpkg.dir) or { return }
    println('Updating packages')

    for pkg in lockfile.packages {
        current_hash := if pkg.latest_commit.len != 0 { pkg.latest_commit } else { pkg.version }
        pkg_name := package_name(pkg.name)
        pkg_location := os.join_path(vpkg.install_dir, pkg_name)
        mut latest_hash := current_hash
        fetch_pkg_info := FetchMethod{ dir: pkg_location }
        latest_hash = fetch_pkg_info.check_version(pkg.method)
        pkg_manifest := load_manifest_file(pkg_location)

        if current_hash != latest_hash {
            updated_packages << InstalledPackage{
                name   : pkg.name
                version: if pkg_manifest.version.len != 0 { pkg_manifest.version } else { latest_hash }
                url    : pkg.url
                method : pkg.method
            }
        }
    }

    lockfile.regenerate(updated_packages, false, vpkg.dir)
    print_status(updated_packages, 'updated')
}

pub fn (mut vpkg Vpkg) get_packages(packages []string, is_final bool) []InstalledPackage {
    mut installed_packages := []InstalledPackage{}
    mut lockfile := read_lockfile(vpkg.dir) or { return installed_packages }
    mut deps := []string{}

    for pkg in packages {
        // pkg_arr := pkg.split('@')
        package := vpkg.fetch_package(pkg)

        if package.name.len != 0 {
            installed_packages << package
            pkg_manifest := load_manifest_file(package.path)
            for dep in pkg_manifest.dependencies {
                dep_idx := deps.index(dep)

                if dep_idx == -1 {
                    deps << dep
                }
            }
        }
    }

    if deps.len != 0 {
        installed_packages << vpkg.get_packages(deps, false)
    }
    
    if is_final {
        for pkg in packages {
            if !vpkg.manifest.is_exist(pkg) {
                vpkg.manifest.dependencies << pkg
            }
        }

        if !('no-save' in vpkg.options) {
            migrate_manifest_file(vpkg.dir, vpkg.manifest, identify_manifest_type(vpkg.manifest_file_path))
        }

        lockfile.regenerate(installed_packages, false, vpkg.dir)
        print_status(installed_packages, 'installed')
    }

    return installed_packages
}

pub fn (vpkg Vpkg) link(dir string) {
    name := if !is_empty_str(vpkg.manifest.name) {vpkg.manifest.name} else {dirname(dir)}
    target := os.join_path(global_modules_dir, name)
    os.symlink(dir, target) or {
        if C.errno == 2 {
            os.mkdir(global_modules_dir) or { return }
        }
        vpkg.link(dir)
    }
    println('Successfully linked the module as $name')
}

pub fn (vpkg Vpkg) unlink(dir string) {
    name := if !is_empty_str(vpkg.manifest.name) {vpkg.manifest.name} else {dirname(dir)}
    target := os.join_path(global_modules_dir, name)
    if os.exists(target) {
        os.rm(os.join_path(global_modules_dir, name))
    }
    if !os.exists(target) {
        println('Successfully unlinked $name')
    }
}

pub fn (vpkg Vpkg) show_package_information() {
    pkg_info := vpkg.manifest
    lockfile := read_lockfile(vpkg.dir) or { return }

    println('Manifest path: ${vpkg.manifest_file_path}')
    println('Package name: ${pkg_info.name}@${pkg_info.version}')
    
    if pkg_info.repo.len != 0 {
        println('Repository: ${pkg_info.repo}')
    } 
    
    println('\nDependencies:')
    for dependency in pkg_info.dependencies {
        println('- ' + dependency)
    }

    println('\nPackage sources:')
    for source_url in pkg_info.sources {
        println('- ' + source_url)
    }

    println('\nInstalled packages:')

    for pkg in lockfile.packages {
        println('- ${pkg.name}@${pkg.version}')
    }
}

fn (vpkg Vpkg) show_version() {
    println('vpkg ${version} for ${os.user_os()}')
    println('Repo: https://github.com/vpkg-project/vpkg \n')
    println('2020 (c) vpkg developers and it\'s contributors.')
}

fn (vpkg Vpkg) show_help() {
    println('Usage: vpkg <COMMAND> [ARGS...] [options]')
    println('\nCOMMANDS\n')

    println('get [packages]                             Fetch and installs packages from the registry or the git repo.')
    println('help                                       Show this help message.')
    println('info                                       Show project\'s package information.')
    println('init                                       Create a package manifest file into the current directory. Defaults to "vpkg".')
    println('install                                    Read the package manifest file and installs the necessary packages.')
    println('link                                       Symlink current module/package to ".vmodules" folder.')
    println('migrate manifest                           Migrate manifest file to a specified format.')
    println('release                                    Release a new version of the module.')
    println('remove [packages]                          Remove packages')
    println('test                                       Test the current lib/app.')
    println('update                                     Update the packages.')
    println('unlink                                     Remove the symlink of current module/package from ".vmodules" folder.')
    println('version                                    Show the version of this program.')

    println('\nOPTIONS\n')
    println('--files [file1,file2]                      Specifiy other locations of test files (For "test" command)')
    println('--force                                    Force download the packages.')
    println('--format [vpkg|vmod]                       Specifiy file format used to init manifest. (For "migrate" and "init" commands)')
    println('--global, -g                               Install the modules/packages into the ".vmodules" folder.')
    println('--inc [major|minor|patch]                  Increment the selected version of the module/package. (For "release" command)')
    println('--state [state_name]                       Indicate the state of the release (alpha, beta, fix) (For "release" command)')
}
