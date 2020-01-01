module api

import (
	net.http
	net.urllib
)

struct Registry {
    base_url string
    registry_file_path string = '/registry.json'
}

struct RegistryRepo {
    packages []Package
}

fn new_registry(base_url string, registry_file_path string) Registry {
    return Registry{
        base_url: base_url,
        registry_file_path: registry_file_path
    }
}

fn (reg Registry) search(name string) Package {
    mut current_pkg := Package{}
	url := urllib.parse(reg.base_url) or { return current_pkg }
    resp := http.get(reg.base_url + reg.registry_file_path) or {
        eprintln('Cannot fetch from ${url.host}')
        return current_pkg
    }

    repo := json.decode(RegistryRepo, resp.text) or {
        eprintln('Failed to read repo.json')
        return current_pkg
    }

    for pkg in repo.packages {
        if pkg.name == name {
            current_pkg = pkg
        }
    }

    return current_pkg
}

struct Vpm {
	base_url string = 'https://vpm.best'
	jsmod_path string = '/jsmod'
}

struct VpmPackage {
    id int
    name string
    url string
    nr_downloads int
}

fn new_vpm(base_url string, jsmod_path string) Vpm {
    return Vpm{ base_url, jsmod_path }
}

fn (vpm Vpm) search(name string) Package {
	resp := http.get('${vpm.base_url}${vpm.jsmod_path}/${name}') or {
        eprintln('Cannot fetch from VPM')
        return Package{}
    }

    repo := json.decode(VpmPackage, resp.text) or {
        eprintln('Failed to parse package information from VPM')
        return Package{}
    }

    return Package{
        name: repo.name,
        url: repo.url,
        method: 'git'
    }
}
