module api

import (
    os
    json
    filepath
)

struct Lockfile {
mut:
    version string
    packages []InstalledPackage
}

fn get_lockfile_path(dir string) string {
    return filepath.join(dir, '.vpkg-lock.json')
}

fn read_lockfile(dir string) ?Lockfile {
    lockfile_path := get_lockfile_path(dir)

    if os.exists(lockfile_path) {
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
 
    for package in packages {
        package_idx := lock.find_package(package.name)

        if package_idx != -1 {
            if remove {
                lock.packages.delete(package_idx)
            } else {
                curr_lock_pkg := lock.packages[package_idx]

                lock.packages[package_idx] = InstalledPackage{
                    name: package.name,
                    path: package.path,
                    version: package.version,
                    url: if package.url == '' || package.url == curr_lock_pkg.url { curr_lock_pkg.url } else { package.url },
                    method: if package.method == '' || package.method == curr_lock_pkg.method { curr_lock_pkg.method } else { package.method },
                    latest_commit: package.latest_commit
                }
            }
        } else {
            if !remove {
                lock.packages << InstalledPackage{
                    name: package.name,
                    path: package.path,
                    version: package.version,
                    url: package.url,
                    method: package.method,
                    latest_commit: package.latest_commit
                }
            }
        }
    }

    // stringify contents
    mut contents := ['{', '   "version": "${lock.version}",', '   "packages": [']

    for i, pkg in lock.packages {
        contents << '      {'
        contents << '         "name": "${pkg.name}",'
        contents << '         "version": "${pkg.version}",'
        contents << '         "url": "${pkg.url}",'
        contents << '         "method": "${pkg.method}",'
        contents << '         "latest_commit": "${pkg.latest_commit}"'

        if i != lock.packages.len-1 {
            contents << '      },'
        } else {
            contents << '      }'
        }
    }

    contents << '   ]'
    contents << '}'

    os.write_file(get_lockfile_path(dir), contents.join('\n'))
}

fn create_lockfile(dir string) Lockfile {
    lockfile_json_arr := ['{', '   "version": "${Version}",', '   "packages": []', '}']
    mut lockfile := os.create(get_lockfile_path(dir)) or { return Lockfile{Version, []InstalledPackage} }
    lockfile_json := lockfile_json_arr.join('\n')
    lockfile.write(lockfile_json)
    defer { lockfile.close() }

    contents := read_lockfile(dir) or {
        return Lockfile{Version, []InstalledPackage}
    }

    return contents
}

