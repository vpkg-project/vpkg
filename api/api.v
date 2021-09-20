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

import api.registries
import api.providers
import v.vmod
import os

pub const meta = vmod.decode(@VMOD_FILE) or { vmod.Manifest{} }

fn default_providers() []Provider {
	return [
		&providers.GitProvider{},
		&providers.MercurialProvider{},
	]
}

fn default_registries() []Registry {
	return [
		&registries.VpkgRegistry{},
		&registries.Vpm{},
	]
}

pub struct Vpkg {
mut:
	dir        string = os.getwd()
	registries []Registry = default_registries()
	providers  []Provider = default_providers()
pub mut:
	manifest   vmod.Manifest
}

pub fn new(dir string) Vpkg {
	real_path := os.real_path(dir)
	if !os.is_dir(real_path) {
		panic('vpkg: provided path is not a directory')
	}

	manifest, _ := load_manifest(real_path) or { panic(err) }
	return Vpkg{ 
		dir: real_path
		manifest: manifest
	}
}