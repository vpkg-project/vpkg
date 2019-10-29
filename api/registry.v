module api

import (
    http
    json
)

fn search_from_vpm(name string) Package {
    resp := http.get('https://vpm.best/jsmod/${name}') or {
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
        method: if is_git_url(repo.url) { 'git' } else { 'http' }
    }
}

fn search_from_registry(name string, url string) Package {
    resp := http.get(url + '/registry.json') or {
        eprintln('Cannot fetch from ${url}')
        return Package{}
    }

    repo := json.decode(Registry, resp.text) or {
        eprintln('Failed to read repo.json')
        return Package{}
    }

    for current_pkg in repo.packages {
        if current_pkg.name == name {
            return current_pkg
        }
    }

    return Package{}
}