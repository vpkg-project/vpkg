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

fn sanitize_package_name(name string) string {
    illegal_chars := ['-']
    mut name_array := name.split('')

    for i := 0; i < name_array.len; i++ {
        current := name_array[i]

        if illegal_chars.index(current) != -1 {
            name_array[i] = '_'
        }
    }

    return name_array.join('')
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

    return sanitize_package_name(pkg_name)
}

fn (vpkg Vpkg) create_modules_dir() string {
    if os.dir_exists(vpkg.dir) {
        os.mkdir(vpkg.dir)
    }

    return vpkg.dir
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
    mut desc_word := 'was'

    if status_type != 'removed' {
        for package in packages {
            println('${package.name}@${package.version}')
        }
    }

    if packages.len > 1 {
        package_word = 'packages'
        desc_word = 'were'
    }

    println('${packages.len} ${package_word} ${desc_word} ${status_type} successfully.')
}