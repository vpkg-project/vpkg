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
import json

struct Lockfile {
mut:
	version  string = meta.version
	dir string [skip]
	packages []Package
}

fn get_lockfile_path(dir string) string {
	return os.join_path(dir, '.vpkg-lock.json')
}

fn read_lockfile(dir string) ?Lockfile {
	lockfile_path := get_lockfile_path(dir)
	if !os.exists(lockfile_path) {
		create_lockfile(dir) ?
		return read_lockfile(dir)
	}

	contents := os.read_file(lockfile_path) or { return error('Cannot read $dir') }
	mut decoded := json.decode(Lockfile, contents) or { return error('Unable to decode lockfile.') }
	decoded.dir = dir
	return decoded
}

fn create_lockfile(dir string) ?Lockfile {
	mut lockfile := os.create(get_lockfile_path(dir)) ?
	lockfile_json := json.encode_pretty(Lockfile{})
	lockfile.write_string(lockfile_json) ?
	defer {	lockfile.close() }
	contents := read_lockfile(dir) ?
	return contents
}

fn (lck &Lockfile) path() string {
	return get_lockfile_path(lck.dir)
}

fn (lck &Lockfile) find_package(name string) int {
	for idx, package in lck.packages {
		if package.name == name {
			return idx
		}
	}
	return -1
}

fn (mut lck Lockfile) remove_package(name string) ? {
	pkg_idx := lck.find_package(name)
	if pkg_idx == -1 {
		return error('package `$name` not found in the lockfile')
	}

	lck.packages.delete(pkg_idx)
}

fn (mut lck Lockfile) upsert_package(package Package) ? {
	mut pkg_idx := lck.find_package(package.name)
	if pkg_idx != -1 {
		// delete the existing package
		lck.packages.delete(pkg_idx)
		lck.packages.insert(pkg_idx, package)
	} else {
		lck.packages << package
	}
}

fn (mut lck Lockfile) close() {
	lck.version = meta.version

	// stringify contents
	contents := json.encode_pretty(lck)
	os.write_file(lck.path(), contents) or {
		// TODO:
		panic(err)
	}
}