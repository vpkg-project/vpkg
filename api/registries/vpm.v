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
import json
import net.http

pub struct Vpm {
	base_url   string = 'https://vpm.vlang.io'
	jsmod_path string = '/jsmod'
}

struct VpmPackage {
	id           int
	name         string
	url          string
	nr_downloads int
}

pub fn (vpm &Vpm) get(package_name string) ?common.Package {
	resp := http.get('$vpm.base_url$vpm.jsmod_path/$package_name') ?
	if resp.status_code != 200 {
		return error_with_code(resp.text, resp.status_code)
	}

	repo := json.decode(VpmPackage, resp.text) ?

	return common.Package{
		name: repo.name
		url: repo.url
		method: 'git'
	}
}

pub fn (vpm &Vpm) index() ?[]common.Package {
	// return nothing for now
	return []common.Package{}
}
