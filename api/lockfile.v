module api

import (
    os
    json
)

fn read_lockfile(dir string) ?Lockfile {
    lockfile_path := dir + '/.vpkg-lock.json'

    if os.file_exists(lockfile_path) {
        contents := os.read_file(lockfile_path) or {
            return error('Cannot read ${dir}')
        }

        decoded := json.decode(Lockfile, contents) or {
            return error('Unable to decode lockfile.')
        }

        return decoded
    } else {
        create_lockfile(dir)
        return read_lockfile(dir)
    }
}

fn (lock Lockfile) find_package(name string) int {
    for idx, package in lock.packages {
        if package.name == name {
            return idx
        }
    }

    return -1
}

fn (lock mut Lockfile) regenerate(packages []InstalledPackage, remove bool, dir string) {    
    if lock.version != Version {
        lock.version = Version
    }
 
    if remove {
        for package in packages {
            package_idx := lock.find_package(package.name)

            if package_idx != -1 {
                lock.packages.delete(package_idx)
            }
        }
    } else {
        for package in packages {
            package_idx := lock.find_package(package.name)

            if package_idx != -1 {
                lock.packages[package_idx] = InstalledPackage{
                    name: package.name,
                    path: package.path
                    version: package.version
                }
            } else {
                lock.packages << InstalledPackage{
                    name: package.name,
                    path: package.path
                    version: package.version
                }
            }
        }
    }

    // stringify contents
    mut contents := ['{', '   "version": "${lock.version}",', '   "packages": [']

    for i, pkg in lock.packages {
        contents << '        {'
        contents << '           "name": "${pkg.name}",'
        contents << '           "version": "${pkg.version}"'

        if i != lock.packages.len-1 {
            contents << '        },'
        } else {
            contents << '        }'
        }
    }

    contents << '   ]'
    contents << '}'

    os.write_file(dir + '/.vpkg-lock.json', contents.join('\n'))
}

fn create_lockfile(dir string) Lockfile {
    lockfile_json_arr := ['{', '   "version": "${Version}",', '   "packages": []', '}']

    lockfile := os.create(dir + '/.vpkg-lock.json') or {
        return Lockfile{Version, []InstalledPackage}
    }

    lockfile_json := lockfile_json_arr.join('\n')

    lockfile.write(lockfile_json)
    defer { lockfile.close() }

    contents := read_lockfile(dir) or {
        return Lockfile{Version, []InstalledPackage}
    }

    return contents
}

