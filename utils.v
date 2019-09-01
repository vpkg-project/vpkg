module main

import os

fn check_git_version(dir string) string {
    version := os.exec('git --git-dir ${dir}/.git log --pretty=format:%H -n 1') or {
        return ''
    }

    return version.output
    }

fn delete_package_contents(path string) bool {
    mut folder_contents := os.ls(path)

    for filename in folder_contents {
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

    if name.starts_with('v-') {
        pkg_name = pkg_name.all_after('v-')
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

    for protocol in protocols {
        if a.starts_with(protocol) {
            return true
        }
    }

    return false
}

fn print_status(packages []InstalledPackage, status_type string) {
    mut package_word := 'package'

    if status_type != 'removed' {
        for package in packages {
            println('${package.name}@${package.version}')
        }
    }

    if packages.len > 1 {
        package_word = 'packages'
    }

    println('${packages.len} ${package_word} was ${status_type} successfully.')
}