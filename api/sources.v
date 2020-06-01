// vpkg 0.7.1
// https://github.com/vpkg-project/vpkg
//
// Copyright (c) 2020 vpkg developers
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

module api

import net.http
import net.urllib
import json

struct Registry {
    base_url           string
    registry_file_path string = '/registry.json'
}

struct RegistryRepo {
    packages []Package
}

fn new_registry(base_url string, registry_file_path string) Registry {
    return Registry{
        base_url: base_url
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
	base_url   string = 'https://vpm.best'
	jsmod_path string = '/jsmod'
}

struct VpmPackage {
    id           int
    name         string
    url          string
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
        name  : repo.name
        url   : repo.url
        method: 'git'
    }
}
