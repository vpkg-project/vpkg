module api

import (
    os
    net.urllib
    filepath
)

fn delete_content(path string) {
    os.rm(path)
}

fn delete_package_contents(path string) bool {
    os.walk(path, delete_content)
    new_folder_contents := os.ls(path) or { return false }

    if new_folder_contents.len == 0 {
        os.rmdir(path)
        return true
    } else {
        return false
    }
}

fn sanitize_package_name(name string) string {
    illegal_chars := ['-']
    mut name_array := name.split('')

    for i, current in name_array {
        if illegal_chars.index(current) != -1 {
            name_array[i] = '_'
        }
    }

    return name_array.join('')
}

fn package_name(path_or_name string) string {
    is_git := is_url(path_or_name)
    mut pkg_name := path_or_name

    if is_git {
        parse_url := urllib.parse(path_or_name) or { return sanitize_package_name(pkg_name) }
        paths := parse_url.path.split('/')

        pkg_name = paths[paths.len-1]
    }

    if path_or_name.contains('.git') {
        pkg_name = pkg_name.replace('.git', '')
    }

    if path_or_name.starts_with('v-') {
        pkg_name = pkg_name.all_after('v-')
    }

    return sanitize_package_name(pkg_name)
}

fn rm_test_execs(dir string) {
    mut base_exec_name := ''
    base_exec_name = filepath.join(os.getwd(), dir.all_before('.v'))
    if !os.exists('${base_exec_name}.exe') || !os.exists(base_exec_name) { return }

    $if windows {
        base_exec_name = base_exec_name + '.exe'
    }

    os.rm(base_exec_name)
}

fn is_url(a string) bool {
    protocols := ['https://', 'git://']

    for protocol in protocols {
        if a.starts_with(protocol) {
            return true
        }
    }

    return false
}

pub fn (vpkg Vpkg) create_modules_dir() string {
    if os.exists(vpkg.install_dir) {
        os.mkdir(vpkg.install_dir) or { return '' }
    }

    return vpkg.install_dir
}

fn print_status(packages []InstalledPackage, status_type string) {
    mut package_word := 'package'
    mut desc_word := 'was'

    if status_type != 'removed' {
        for package in packages {
            pkg_commit := if package.version != package.latest_commit || package.latest_commit.len != 0 { 
                ' at commit ' + package.latest_commit
            } else {
                ''
            } 

            println('${package.name}@${package.version}${pkg_commit}')
        }
    }

    if packages.len > 1 {
        package_word = 'packages'
        desc_word = 'were'
    }

    println('${packages.len} ${package_word} ${desc_word} ${status_type} successfully.')
}