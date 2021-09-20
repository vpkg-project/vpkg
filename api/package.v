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

import api.common
import os
import net.urllib

pub interface Registry {
	base_url string
	get(package_name string) ?common.Package
	index() ?[]common.Package
}

pub fn (registries []Registry) fetch(name string) ?common.Package {
	for i, registry in registries {
		return registry.get(name) or {
			if i < registries.len - 1 {
				continue
			} else {
				return err
			}
		}
	}

	return error('package `$name` not found')
}

struct FetchPackageOptions{
	update bool
	force bool
	name string
}

enum PackageState {
	installed
	fetched
	updated
	removed
}

struct Package {
	name string
	url string
	version string
	state PackageState [skip]
}

fn (vpkg &Vpkg) fetch_package(path_or_name string, options FetchPackageOptions) ?Package {
	// TODO: Check if package exists
	// TODO: support for update

	// if !option.force {
	// 	// TODO: do something here
	// 	return error('forced')
	// }

	if url := urllib.parse(path_or_name) {
		mut provider := vpkg.providers.find_by_url(&url) ?
		provider.set_output_path(os.join_path(vpkg.dir, 'modules'))

		pkg_name := if options.name.len != 0 { 
			options.name 
		} else { 
			sanitize_package_name(url.path.all_after_last('/')) 
		}

		installed_path := provider.fetch(&url, to_fs_path(pkg_name)) ?
		installed_path_uri := urllib.parse('file://$installed_path') ?
		version := provider.get_version(&installed_path_uri)

		return Package{
			name: pkg_name
			url: url.str()
			version: version
			state: .installed
		}
	} else {
		found_pkg := vpkg.registries.fetch(path_or_name) ?

		// use the existing name when returning the installed package.
		return vpkg.fetch_package(found_pkg.url, { 
			name: path_or_name, 
			force: options.force 
		})
	}

	return error('package `$path_or_name` not found.')
}

// For `vpkg remove` command
pub fn (vpkg &Vpkg) remove_packages(packages []string) ?int {
	mut remove_count := 0
	mut lockfile := read_lockfile(vpkg.dir) ?
	defer { lockfile.close() }
	
	installed_packages := lockfile.packages.clone()
	for package in installed_packages {
		package_location_url := urllib.parse('file://' + os.join_path(vpkg.dir, 'modules', to_fs_path(package.name))) ?
		package_url := urllib.parse(package.url) ?
		mut provider := vpkg.providers.find_by_url(package_url) ?
		provider.remove(&package_location_url) ?
		lockfile.remove_package(package.name) ?
		remove_count++
	}

	return remove_count
}

pub struct GetPackagesOptions {
	force bool
	update bool
}

// For `vpkg get`
pub fn (mut vpkg Vpkg) get_packages(packages []string, options GetPackagesOptions) ?[]Package {
	if packages.len == 0 {
		return error('no packages to download')
	}

	mut installed_packages := []Package{}
	mut lockfile := read_lockfile(vpkg.dir) ?
	defer { lockfile.close() }

	for pkg_path_or_name in packages {
		println('installing ${pkg_path_or_name}...')
		installed_package := vpkg.fetch_package(pkg_path_or_name, {}) ?
		lockfile.upsert_package(installed_package) ?

		installed_packages << installed_package

		// should be done when all of the deps are installed i guess
		if pkg_path_or_name !in vpkg.manifest.dependencies {
			vpkg.manifest.dependencies << pkg_path_or_name
		}
		// TODO: inspect package dependencies
	}

	// if packages.len == 0 {
	// if 'no-save' !in vpkg.options {
	//     convert_manifest(vpkg.dir, vpkg.manifest, identify_manifest_type(vpkg.manifest_file_path))
	// }
	return installed_packages
}
