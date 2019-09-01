module main

import (
    os
    term
    json
)

fn (vpkg Vpkg) load_manifest_file() PkgManifest {
    manifest_file_path := vpkg.manifest_file_path

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

    if os.file_exists('${dir}/.vpm.json') {
        return '${dir}/.vpm.json'
    }

    if os.file_exists('${dir}/.vpkg.json') {
        return '${dir}/.vpkg.json'
    }

    return ''
}