module api

import (
    os
    filepath
)

pub fn (vpkg Vpkg) migrate_manifest() {
    m_type := if 'format' in vpkg.options { vpkg.options['format'] } else { 'vpkg' }

    migrate_manifest_file(vpkg.dir, vpkg.manifest, m_type)
}

fn (vpkg Vpkg) test_package() {
    mut pwd_var := ''
    mut separator := '/'

    $if linux {
        pwd_var = '\$PWD'
        separator = '/'
    } $else {
        pwd_var = '%cd%'
        separator = '\\'
    }

    package_path := filepath.join(pwd_var, '..' + separator)
    package_name := os.filename(os.getwd())
    mut files := []string

    if os.exists('${package_name}_test.v') {
        files << '${package_name}_test.v'
    }

    if 'files' in vpkg.options {
        files << vpkg.options['files'].split(',')
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
        mut base_exec_name := ''

        if os.is_dir(file) {
            folder_contents := os.ls(file) or { return }

            for f in folder_contents {
                base_exec_name = filepath.join(os.getwd(), file, f.all_before('.v'))
                if !os.exists('${base_exec_name}.exe') || !os.exists(base_exec_name) { continue }

                $if windows {
                    base_exec_name = base_exec_name + '.exe'
                }
 
                os.rm(base_exec_name)
            }
        } else {
            base_exec_name = filepath.join(os.getwd(), file.all_before('.v'))
            if !os.exists('${base_exec_name}.exe') || !os.exists(base_exec_name) { continue }

            $if windows {
                base_exec_name = base_exec_name + '.exe'
            }

            os.rm(base_exec_name)
        }
    }
}

pub fn (vpkg Vpkg) create_manifest_file() {
    pkg_name := filepath.filename(vpkg.dir)
    
    mut pkg_manifest_contents := []string
    mut manifest_filename := 'vpkg.json'



    match vpkg.options['format'] {
        'vpkg' {
            pkg_manifest_contents << '{\n   "name": "${pkg_name}",'
            pkg_manifest_contents << '   "version": "1.0",'
            pkg_manifest_contents << '   "author": ["Author Name <author@example.com>"],'
            pkg_manifest_contents << '   "repo": "https://github.com/username/repo",'
            pkg_manifest_contents << '   "dependencies": []'
            pkg_manifest_contents << '}' 
        }
        'vmod' {
            manifest_filename = 'v.mod'
            pkg_manifest_contents << 'Module {\n   name: \'${pkg_name}\','
            pkg_manifest_contents << '   version: \'1.0\','
            pkg_manifest_contents << '   dependencies: []'
            pkg_manifest_contents << '}' 
        }
        else {
            pkg_manifest_contents << '{\n   "name": "${pkg_name}",'
            pkg_manifest_contents << '   "version": "1.0",'
            pkg_manifest_contents << '   "author": ["Author Name <author@example.com>"],'
            pkg_manifest_contents << '   "repo": "https://github.com/username/repo",'
            pkg_manifest_contents << '   "dependencies": []'
            pkg_manifest_contents << '}' 
        }
    }

    mut manifest_data := os.create(filepath.join(vpkg.dir, manifest_filename)) or {
        eprintln('Package manifest file was not created successfully.')
        return
    }

    manifest_data.write(pkg_manifest_contents.join('\n'))
    defer { manifest_data.close() }

    println('Package manifest file was created successfully.')
}

pub fn (vpkg Vpkg) install_packages(dir string) {
    println('Installing packages')
    pkg_info := vpkg.manifest
    packages := pkg_info.dependencies
    vpkg.get_packages(packages, true)
}

pub fn (vpkg Vpkg) remove_packages(packages []string) {
    mut removed_packages := []InstalledPackage
    mut lockfile := read_lockfile(vpkg.dir) or {
        println(err)
        return
    }

    for package in packages {
        pkg_name := if package.starts_with('v-') { package.all_after('v-') } else { package }
        status := delete_package_contents(filepath.join(vpkg.install_dir, pkg_name))

        if status { removed_packages << InstalledPackage{ name: package } }
    }

    lockfile.regenerate(removed_packages, true, vpkg.dir)
    print_status(removed_packages, 'removed')
}

pub fn (vpkg Vpkg) update_packages() {    
    mut updated_packages := []InstalledPackage
    println('Fetching lockfile')
    mut lockfile := read_lockfile(vpkg.dir) or { return }
    println('Updating packages')

    for pkg in lockfile.packages {
        current_hash := if pkg.latest_commit.len != 0 { pkg.latest_commit } else { pkg.version }
        pkg_name := package_name(pkg.name)
        pkg_location := filepath.join(vpkg.install_dir, pkg_name)
        mut latest_hash := current_hash
        fetch_pkg_info := FetchMethod{ dir: pkg_location }
        latest_hash = fetch_pkg_info.check_version(pkg.method)
        pkg_manifest := load_manifest_file(pkg_location)

        if current_hash != latest_hash {
            updated_packages << InstalledPackage{
                name: pkg.name,
                version: if pkg_manifest.version.len != 0 { pkg_manifest.version } else { latest_hash },
                url: pkg.url,
                method: pkg.method
            }
        }
    }

    lockfile.regenerate(updated_packages, false, vpkg.dir)
    print_status(updated_packages, 'updated')
}

pub fn (vpkg Vpkg) get_packages(packages []string, is_final bool) []InstalledPackage {
    mut installed_packages := []InstalledPackage
    mut lockfile := read_lockfile(vpkg.dir) or { return installed_packages }
    mut deps := []string

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
        lockfile.regenerate(installed_packages, false, vpkg.dir)
        print_status(installed_packages, 'installed')
    }

    return installed_packages
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
    println('vpkg ${Version} for ${os.user_os()}')
    println('Repo: https://github.com/vpkg-project/vpkg \n')
    println('2019 (c) Ned Palacios and it\'s contributors.')
}

fn (vpkg Vpkg) show_help() {
    println('Usage: vpkg <COMMAND> [ARGS...] [options]')

    println('\nCOMMANDS\n')

    println('get [packages]                             Fetch and installs packages from the registry or the git repo.')
    println('help                                       Prints this help message.')
    println('info                                       Show project\'s package information.')
    println('init [--format=vpkg|vmod]                  Creates a package manifest file into the current directory. Defaults to "vpkg".')
    println('install                                    Reads the package manifest file and installs the necessary packages.')
    println('migrate manifest                           Migrate manifest file to a specified format.')
    println('remove [packages]                          Removes packages')
    println('update                                     Updates packages.')
    println('version                                    Prints the version of this program.')
    println('test                                       Tests the current lib/app.')

    println('\nOPTIONS\n')
    println('--global, -g                               Installs the modules/packages into the `.vmodules` folder.')
    println('--force                                    Force download the packages.')
    println('--files [file1,file2]                      Specifies other locations of test files (For "test" command)')
}
