module main

import (
    os
    json
)

fn load_manifest_file(dir string) PkgManifest {
    manifest_file_path := get_manifest_file_path(dir)

    if manifest_file_path.ends_with('v.mod') {
        return open_vmod(manifest_file_path)
    } else {
        manifest_file_contents := os.read_file(manifest_file_path) or {
            return PkgManifest{}
        }

        contents := json.decode(PkgManifest, manifest_file_contents) or {
            return PkgManifest{}
        }

        return contents
    }
}

fn get_manifest_file_path(dir string) string {
    if os.file_exists('${dir}/v.mod') {
        return '${dir}/v.mod'
    }

    if os.file_exists('${dir}/.vpkg.json') {
        return '${dir}/.vpkg.json'
    }

    if os.file_exists('${dir}/vpkg.json') {
        return '${dir}/vpkg.json'
    }

    if os.file_exists('${dir}/.vpm.json') {
        return '${dir}/.vpm.json'
    }

    return ''
}

fn migrate_manifest_file(dir string, manifest PkgManifest, format string) {
    filepath := get_manifest_file_path(dir)

    match format {
        'vmod' => {manifest_to_vmod(manifest, dir)}
        'vpkg' => {manifest_to_vpkg(manifest, dir)}
    }

    if filepath.ends_with('.vpkg.json') && format == 'vpkg' {
        $if windows {
            os.mv(filepath, dir + '\\vpkg.json')
        } $else {
            os.mv(filepath, dir + '/vpkg.json')
        }
    } 
}

fn convert_to_vpm(name string) string {
    name_array := name.split('/')
    mut vpm_pkg_name_array := []string

    vpm_pkg_name_array << package_name(name_array[2])
    vpm_pkg_name_array << package_name(name_array[3])

    return vpm_pkg_name_array.join('.')
}

fn (manifest PkgManifest) to_vmod() string {
    mut vmod_contents := ['Module {\n']
    vmod_contents << '   name: \'${manifest.name}\'\n'
    vmod_contents << '   version: \'${manifest.version}\'\n'
    vmod_contents << '   deps: ['

    for i, dep in manifest.dependencies {
        depp := if is_git_url(dep) { convert_to_vpm(dep) } else { dep }

        vmod_contents << '\'${depp}\''

        if i != 0 && i != manifest.dependencies.len {
            vmod_contents << ','
        }
    }

    vmod_contents << ']\n'
    vmod_contents << '}'

    return vmod_contents.join('')
}

fn (manifest PkgManifest) to_vpkg_json() string {
    mut vpkg_json_contents := []string

    vpkg_json_contents << '{\n    "name": "${manifest.name}",\n'
    vpkg_json_contents << '    "version": "${manifest.version}",\n'
    vpkg_json_contents << '    "author": [\n'
    
    for i, author in manifest.author {
        vpkg_json_contents << '        "${author}"'

        if i != 0 && i != manifest.author.len {
            vpkg_json_contents << ','
        }
        
        vpkg_json_contents << '\n'
    }

    vpkg_json_contents << '    ],\n'

    vpkg_json_contents << '    "repo": "${manifest.repo}",\n'
    vpkg_json_contents << '    "dependencies": [\n'

    for i, dep in manifest.dependencies {
        vpkg_json_contents << '        "${dep}"'

        if i != 0 && i != manifest.dependencies.len {
            vpkg_json_contents << ','
        }

        vpkg_json_contents << '\n'
    }
    vpkg_json_contents << '    ]\n'
    vpkg_json_contents << '}' 

    return vpkg_json_contents.join('')
}

fn manifest_to_vmod(manifest PkgManifest, dir string) {
    vmod_file := os.create(dir + '/v.mod') or {
        return
    }

    vmod_contents_str := manifest.to_vmod()

    vmod_file.write(vmod_contents_str)
    defer { vmod_file.close() }
}

fn manifest_to_vpkg(manifest PkgManifest, dir string) {
    vpkg_file := os.create(dir + '/vpkg.json') or {
        return
    }

    vpkg_contents_str := manifest.to_vpkg_json()

    vpkg_file.write(vpkg_contents_str)
    defer { vpkg_file.close() }
}