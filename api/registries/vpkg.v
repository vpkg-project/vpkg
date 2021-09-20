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

module registries

import api.common
import net.http
import net.urllib
import json

pub struct VpkgRegistry {
	base_url       string = 'https://vpkg-project.github.io/registry/registry.json'
	index_endpoint string = '/registry.json'
}

struct RegistryRepo {
	packages []common.Package
}

fn (reg &VpkgRegistry) index() ?[]common.Package {
	mut url := urllib.parse(reg.base_url) ?
	resp := http.get(url.str()) ?
	if resp.status_code != 200 {
		return error_with_code(resp.text, resp.status_code)
	}

	repo := json.decode(RegistryRepo, resp.text) ?
	return repo.packages
}

fn (reg &VpkgRegistry) get(package_name string) ?common.Package {
	packages := reg.index() ?

	for pkg in packages {
		if pkg.name == package_name {
			return pkg
		}
	}

	return error_with_code('package `$package_name` not found', 404)
}
