module main

import os
import json

fn load_package_file() PkgInfo {
    vpkg_file := os.read_file('${os.getwd()}/.vpkg.json') or {
        eprintln(term.red('No .vpkg.json found.'))
        return PkgInfo{'', '', '', []string}
    }

    pkg_info := json.decode(PkgInfo, vpkg_file) or {
        eprintln(term.red('Error decoding .vpkg.json'))
        return PkgInfo{'', '', '', []string}
    }

    return pkg_info
}

fn check_git_version(dir string) string {
    version := os.exec('git --git-dir ${dir}/.git log --pretty=format:%H -n 1')

    return version
}

fn read_lockfile() ?Lockfile {
    empty_lockfile := Lockfile{Version, map[string]InstalledPackage{}}

    contents := os.read_file(LockfilePath) or {
        eprintln('Lockfile not found.')

        return empty_lockfile
    }

    decoded := json.decode(Lockfile, contents) or {
        eprintln('Error decoding lockfile.')

        return empty_lockfile
    }

    return decoded
}

fn (lock mut Lockfile) regenerate(packages []InstalledPackage) {
    if lock.version != Version {
        lock.version = Version
    }

    for package in packages {
        lock.packages[package.name] = InstalledPackage{
            path: package.path,
            version: package.version
        }
    }

    contents := json.encode(lock)

    os.write_file(LockfilePath, contents)
}

fn create_lockfile() Lockfile {
    empty_lockfile := Lockfile{Version, map[string]InstalledPackage{}}

    lockfile := os.create(LockfilePath) or {
        return empty_lockfile
    }

    lockfile_contents := Lockfile{
        version: Version,
        packages: map[string]InstalledPackage{}
    }

    lockfile_json := json.encode(lockfile_contents)

    lockfile.write(lockfile_json)
    lockfile.close()

    contents := read_lockfile() or {
        return empty_lockfile
    }

    return contents
}


fn delete_package_contents(path string) bool {
    mut folder_contents := os.ls(path)

    for i := 0; i < folder_contents.len; i++ {
        filename := folder_contents[i]
        filepath := '${path}/${filename}'

        if os.dir_exists(filepath) {
            delete_package_contents(filepath)
        } else {
            os.rm(filepath)
        }
    }

    folder_contents = os.ls(path)

    if folder_contents.len == 0 {
        os.rmdir(path)

        return true
    } else {
        return false
    }
}

fn package_name(name string) string {
    is_git := is_git_url(name)
    mut pkg_name := name

    if is_git {
        pkg_name = os.filename(name)
    }

    if is_git && name.contains('.git') {
        pkg_name = pkg_name.replace('.git', '')
    }

    return pkg_name
}

fn create_modules_dir() string {
    if os.dir_exists(ModulesDir) {
        os.mkdir(ModulesDir)
    }

    return ModulesDir
}

fn is_git_url(a string) bool {
    protocols := ['https://', 'git://']

    for i := 0; i < protocols.len; i++ {
        if a.starts_with(protocols[i]) {
            return true
        }
    }

    return false
}