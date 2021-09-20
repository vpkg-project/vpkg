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

import os
import readline

// migrate migrates the existing vpkg.json format to v.mod
// command: vpkg migrate-manifest
pub fn (vpkg &Vpkg) migrate_manifest() ? {
	mut vmod_file := os.open_file(os.join_path(vpkg.dir, 'vpkg.json'), 'rw') ?
	defer { vmod_file.close() }

	vmod_file.write_string(stringify_manifest(&vpkg.manifest)) ?
}

//
// For `vpkg release` command
pub fn (vpkg &Vpkg) release_module_to_git() {
	// exit_code := os.system('v test $vp')

// TODO: must be relegated to the providers
	// if exit_code != 0 {
	// 	println('Releasing $vpkg.manifest.name ${vpkg.manifest.version}...')
	// 	os.system('git tag -a v$vpkg.manifest.version')
	// }
}

// For `vpkg init` command
pub fn init_manifest_file(dir string) ? {
	pkg_name := os.file_name(dir)
	manifest_path := os.join_path(dir, 'v.mod')
	name := readline.read_line('Module name: ') or { pkg_name }
	version := readline.read_line('Version (1.0.0): ') or { '1.0.0' }
	manifest := stringify_manifest(
		name: name
		version: version
		author: 'Your Author Name <author@example.com>'
	)
	os.write_file(manifest_path, manifest) ?
}

// For `vpkg info`
pub fn (vpkg &Vpkg) print_info() ? {
	lockfile := read_lockfile(vpkg.dir) ?
	println('${vpkg.manifest.name}@${vpkg.manifest.version} (${vpkg.manifest.repo_url})')
	println('\nDependencies:')
	for dependency in vpkg.manifest.dependencies {
		println('- ' + dependency)
	}

	println('\nInstalled packages:')
	for pkg in lockfile.packages {
		println('- $pkg.name@$pkg.version')
	}
}
