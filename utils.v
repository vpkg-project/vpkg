module main

import os
import json

// fn read_lockfile() string {
    
// }

// fn create_lockfile() ?string {
//     // TODO: Create lockfile for easy tracking of modules

//     lockfile_path := '${os.getwd()}/.vpkg.lock'
    
//     os.create(lockfile_path) or {
        
//     }


//     if !os.file_exists(lockfile_path) {

//     }
// }


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