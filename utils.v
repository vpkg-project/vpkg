module main

import os
import json

// fn create_and_update_lockfile() {
//     // TODO: Create lockfile for easy tracking of modules

//     lockfile_path := '${os.getcwd()}/.vpkg.lock'
//     mut lockfile := os.read_file(lockfile_path) or {
//         return
//     }


//     // if !os.file_exists(lockfile_path) {

//     // }
// }

fn delete_package_contents(path string) {
    folder_contents := os.ls(path)

    for i := 0; i < folder_contents.len; i++ {
        filename := folder_contents[i]
        filepath := '${path}/${filename}'
        is_dir := os.is_dir(filepath)

        if is_dir {
            delete_package_contents(filepath)
        } else {
            os.rm(filepath)
        }
    }

    if folder_contents.len == 0 {
        os.rmdir(path)
    }
}

fn package_name(name string) string {
    mut is_git := is_git_url(name)
    mut pkg_name := name

    if is_git {
        pkg_name = os.filename(name)
    }

    if is_git && name.contains('.git') {
        pkg_name = pkg_name.replace('.git', '')
    }

    return pkg_name
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