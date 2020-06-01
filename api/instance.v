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

import os

const (
    version = '0.7.1'
    global_modules_dir = os.home_dir() + '.vmodules'
)

pub struct Vpkg {
pub mut:
    command            string
    options            map[string]string
    unknown            []string
    dir                string
    install_dir        string
    manifest_file_path string
    manifest           PkgManifest
    is_global          bool
    sources            []string
}

pub fn new(dir string) Vpkg {
    instance := Vpkg{
        dir                : dir
        manifest_file_path : get_manifest_file_path(dir)
        install_dir        : os.join_path(dir, 'modules')
        is_global          : false
        manifest           : load_manifest_file(dir)
    }

    return instance
}

pub fn (mut vpkg Vpkg) run(args []string) {
	argv_ := vargs_parse(args, 0)
	vpkg.command = argv_.command
    vpkg.options = argv_.options
    vpkg.unknown = argv_.unknown
    vpkg.is_global = 'g' in vpkg.options || 'global' in vpkg.options

    match vpkg.command {
        'get'     { vpkg.get_packages(vpkg.unknown, true) }
        'help'    { vpkg.show_help() }
        'info'    { vpkg.show_package_information() }
        'init'    { vpkg.create_manifest_file() }
        'link'    { vpkg.link(vpkg.dir) }
        'install' { vpkg.install_packages(vpkg.dir) }
        'remove'  { vpkg.remove_packages(vpkg.unknown) }
        'migrate' { if vpkg.unknown[0] == 'manifest' {vpkg.migrate_manifest()} else {vpkg.show_help()} }
        'update'  { vpkg.update_packages() }
        'unlink'  { vpkg.unlink(vpkg.dir) }
        'version' { vpkg.show_version() }
        'test'    { vpkg.test_package() }
        'release' { vpkg.release_module_to_git() }
        else      { vpkg.show_help() }
    }
}
