module main

import (
    os
    term
    vargs
)

fn (vpkg Vpkg) migrate_manifest() {
    m_type := if 'format' in vpkg.options { vpkg.options['format'] } else { 'vpkg' }

    migrate_manifest_file(vpkg.dir, vpkg.manifest, m_type)
}

fn (vpkg Vpkg) create_manifest_file() {
    pkg_name := os.filename(vpkg.dir)
    
    mut pkg_manifest_contents := []string
    mut manifest_filename := 'vpkg.json'

    switch vpkg.options['format'] {
        case 'vpkg':
            pkg_manifest_contents << '{\n   "name": "${pkg_name}",'
            pkg_manifest_contents << '   "version": "1.0",'
            pkg_manifest_contents << '   "author": ["Author Name <author@example.com>"],'
            pkg_manifest_contents << '   "repo": "https://github.com/username/repo",'
            pkg_manifest_contents << '   "dependencies": []'
            pkg_manifest_contents << '}' 
        case 'vmod':
            manifest_filename = 'v.mod'
            pkg_manifest_contents << 'Module {\n   name: \'${pkg_name}\','
            pkg_manifest_contents << '   version: \'1.0\','
            pkg_manifest_contents << '   dependencies: []'
            pkg_manifest_contents << '}' 
        default:
            pkg_manifest_contents << '{\n   "name": "${pkg_name}",'
            pkg_manifest_contents << '   "version": "1.0",'
            pkg_manifest_contents << '   "author": ["Author Name <author@example.com>"],'
            pkg_manifest_contents << '   "repo": "https://github.com/username/repo",'
            pkg_manifest_contents << '   "dependencies": []'
            pkg_manifest_contents << '}' 
    }

    manifest_data := os.create('${vpkg.dir}/${manifest_filename}') or {
        eprintln('Package manifest file was not created successfully.')
        return
    }

    manifest_data.write(pkg_manifest_contents.join('\n'))
    defer { manifest_data.close() }

    println('Package manifest file was created successfully.')
}

fn (vpkg Vpkg) install_packages(dir string) {
    pkg_info := vpkg.manifest

    println('Installing packages')
    packages := pkg_info.dependencies

    vpkg.get_packages(packages)
}

fn (vpkg Vpkg) remove_packages(packages []string) {
    mut removed_packages := []InstalledPackage
    mut lockfile := read_lockfile(vpkg.dir) or {
        println(err)
        return
    }

    for package in packages {
        pkg_name := if package.starts_with('v-') { package.all_after('v-') } else { package }
        status := delete_package_contents('${vpkg.dir}/${pkg_name}')

        if status {
            removed_packages << InstalledPackage{
                name: package
            }
        }
    }

    lockfile.regenerate(removed_packages, true, vpkg.dir)
    print_status(removed_packages, 'removed')
}

fn (vpkg Vpkg) update_packages() {    
    mut updated_packages := []InstalledPackage

    println('Fetching lockfile')
    mut lockfile := read_lockfile(vpkg.dir) or { return }

    println('Updating packages')

    for pkg in lockfile.packages {
        current_hash := pkg.version
        pkg_name := package_name(pkg.name)
        pkg_location := '${vpkg.dir}/${pkg_name}'

        mut latest_hash := current_hash

        os.exec('git -C ${pkg_location} fetch')
        latest_hash = check_git_version(pkg_location)

        if current_hash != latest_hash {
            os.exec('git -C ${pkg_location} pull')

            updated_package := InstalledPackage{
                name: pkg.name,
                version: latest_hash
            }

            updated_packages << updated_package
        }
    }

    lockfile.regenerate(updated_packages, false, vpkg.dir)
    print_status(updated_packages, 'updated')
}

fn (vpkg Vpkg) get_packages(packages []string) {
    mut installed_packages := []InstalledPackage
    mut lockfile := read_lockfile(vpkg.dir) or { return }

    for i := 0; i < packages.len; i++ {
        package := vpkg.get_package(packages[i])

        if package.name.len != 0 {
            installed_packages << package
        }
    }

    lockfile.regenerate(installed_packages, false, vpkg.dir)
    print_status(installed_packages, 'installed')
}

fn (vpkg Vpkg) show_package_information() {
    pkg_info := vpkg.manifest
    lockfile := read_lockfile(vpkg.dir) or {
        return
    }

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
    println('Repo: https://github.com/v-pkg/vpkg \n')
    println('2019 (c) Ned Palacios and it\'s contributors.')
}

fn (vpkg Vpkg) show_help() {
    println('vpkg ${Version}')
    println('An alternative package manager for V.')

    println('\nUSAGE\n')
    println('vpkg <COMMAND> [ARGS...] [options]')

    println('\nCOMMANDS\n')

    println('get [packages]                             Fetch and installs packages from the registry or the git repo.')
    println('help                                       Prints this help message.')
    println('info                                       Show project\'s package information.')
    println('init [--format=vpkg|vmod]                  Creates a package manifest file into the current directory. Defaults to "vpkg".')
    println('install                                    Reads the package manifest file and installs the necessary packages.')
    println('migrate manifest [--format=vpkg|vmod]      Migrate manifest file to a specified format.')
    println('remove [packages]                          Removes packages')
    println('update                                     Updates packages.')
    println('version                                    Prints the version of this program.')

    println('\nOPTIONS\n')
    println('--global, -g                               Installs the modules/packages into the `.vmodules` folder.')
    println('--force                                    Force download the packages.')
}