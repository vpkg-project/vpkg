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
import strings
import v.vmod
import json

struct LegacyManifest {
	name       string
	author     []string
	test_files []string
	sources    []string
	repo       string
mut:
	version      string
	dependencies []string
}

fn stringify_manifest(mni &vmod.Manifest) string {
	mut wr := strings.new_builder(200)
	wr.writeln('Module {')
	wr.writeln('\tname: \'$mni.name\'')
	wr.writeln('\tversion: \'$mni.version\'')
	for name, val in mni.unknown {
		wr.write_string('\t$name: ')
		if val.len > 1 {
			wr.write_string(' [')
			for i, value in val {
				wr.write_string('\'$value\'')
				if i < val.len {
					wr.write_string(', ')
				}
			}
			wr.writeln(']')
		} else {
			wr.writeln('\'${val[0]}\'')
		}
	}
	wr.write_string('\tdependencies: \n[')
	for i, dep in mni.dependencies {
		wr.write_string('\'$dep\'')
		if i < mni.dependencies.len {
			wr.write_string(', ')
		}
	}
	wr.writeln(']\n}')
	return wr.str()
}

fn load_legacy_manifest(manifest_path string) ?vmod.Manifest {
	file := os.read_file(manifest_path) ?
	legacy_data := json.decode(LegacyManifest, file) ?

	return vmod.Manifest{
		name: legacy_data.name
		repo_url: legacy_data.repo
		version: legacy_data.version
		dependencies: legacy_data.dependencies
		unknown: map{
			'authors':     legacy_data.author
			'test_files':  legacy_data.test_files
			'source_urls': legacy_data.sources
		}
	}
}

pub fn load_manifest(dir string) ?(vmod.Manifest, string) {
	mut manifest_path := ''
	mut format := ''
	for filename in ['v.mod', 'vpkg.json'] {
		file_path := os.join_path(dir, filename)
		if !os.exists(file_path) {
			continue
		}
		manifest_path = file_path
		format = filename
		break
	}
	match format {
		'v.mod' {
			manifest := vmod.from_file(manifest_path) ?
			return manifest, manifest_path
		}
		'vpkg.json' {
			println('vpkg.json is deprecated and will be removed in the future in favor of v.mod. Please run "vpkg migrate" to migrate your package data to v.mod format.')
			manifest := load_legacy_manifest(manifest_path) ?
			return manifest, manifest_path
		}
		else {
			return error('no manifest file detected.')
		}
	}
}
