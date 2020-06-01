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
import json
import strings

struct PkgManifest {
    name         string
    author       []string
    test_files   []string
    sources      []string
    repo         string
mut:
    version      string
    dependencies []string
}

struct ManifestWriter {
    key_quotes   string
    val_quotes   string
    opening      string
    closing      string
    colon        string
    comma        string
    spaces_count int
pub mut:
    contents     strings.Builder
}

fn new_vpkg_json() ManifestWriter {
    return ManifestWriter{
        key_quotes  : '"',
        val_quotes  : '"',
        opening     : '{',
        closing     : '}',
        colon       : ':',
        comma       : ',',
        spaces_count: 4,
        contents    : strings.new_builder(1024)
    }
}

fn new_vmod() ManifestWriter {
    return ManifestWriter{
        key_quotes  : '',
        val_quotes  : '\'',
        opening     : 'Module {',
        closing     : '}',
        colon       : ':',
        comma       : ',',
        spaces_count: 4,
        contents    : strings.new_builder(1024)
    }
}


fn (mut mw ManifestWriter) init_write() {
    mw.contents.writeln(mw.opening)
}

fn (mut mw ManifestWriter) close() {
    mw.contents.write('\n' + mw.closing)
}

fn (mut mw ManifestWriter) write(key string, val string, newline bool) {
    if mw.contents.len > mw.initial_content().len {
        mw.contents.writeln(mw.comma)
    }

    key_with_quotes := mw.key_quotes + key + mw.key_quotes
    val_with_quotes := mw.val_quotes + val + mw.val_quotes
    mut text := key_with_quotes + '${mw.colon} ' + val_with_quotes

    if mw.contents.len == 0 { mw.init_write() }

    if (val.starts_with('[') && val.ends_with(']')) || (val.starts_with('{') && val.starts_with('}')) {
        text = key_with_quotes + '${mw.colon} ' + val
    }

    if newline {
        mw.contents.writeln(strings.repeat(` `, mw.spaces_count) + text)
    } else {
        mw.contents.write(strings.repeat(` `, mw.spaces_count) + text)
    }
}

fn (mw ManifestWriter) initial_content() string {
    text := mw.opening + '\n'
    return text
}

fn (mut mw ManifestWriter) write_arr(key string, arr []string, newline bool) {
    if mw.contents.len != mw.initial_content().len {
        mw.contents.writeln(mw.comma)
    }

    key_with_quotes := mw.key_quotes + key + mw.key_quotes

    if mw.contents.len == 0 { mw.init_write() }

    mw.contents.write(strings.repeat(` `, mw.spaces_count) + key_with_quotes + '${mw.colon} ')

    if newline {
        mw.contents.writeln('[')
    } else {
        mw.contents.write('[')
    }

    for i, val in arr {
        mut text := mw.val_quotes + val + mw.val_quotes

        if arr.len > 1 && i != arr.len-1 {
            text = text + '${mw.comma} '
        }

        if newline {
            mw.contents.write(strings.repeat(` `, mw.spaces_count*2) + text)
        } else {
            mw.contents.write(text)
        }
    }

    if newline {
        mw.contents.write('\n' + strings.repeat(` `, mw.spaces_count) + ']')
    } else {
        mw.contents.write(']')
    }
}

fn load_manifest_file(dir string) PkgManifest {
    manifest_file_path := get_manifest_file_path(dir)

    if manifest_file_path.ends_with('v.mod') {
        return open_vmod(manifest_file_path)
    } else {
        manifest_file_contents := os.read_file(manifest_file_path) or { return PkgManifest{} }
        contents := json.decode(PkgManifest, manifest_file_contents) or { return PkgManifest{} }

        return contents
    }
}

fn get_manifest_file_path(dir string) string {
    manifest_files := ['v.mod', '.vpkg.json', 'vpkg.json', '.vpm.json']

    for f in manifest_files {
        m_path := os.join_path(dir, f)

        if os.exists(m_path) {
            return m_path
        }
    }

    return ''
}

fn identify_manifest_type(path string) string {
    if path.ends_with('v.mod') {
        return 'vmod'
    }

    if path.ends_with('.vpkg.json') || path.ends_with('vpkg.json') {
        return 'vpkg'
    }

    return ''
}

fn migrate_manifest_file(dir string, manifest PkgManifest, format string) {
    m_path := get_manifest_file_path(dir)

    match format {
        'vmod' {manifest_to_vmod(manifest, dir)}
        'vpkg' {manifest_to_vpkg(manifest, dir)}
        else { return }
    }

    if m_path.ends_with('.vpkg.json') && format == 'vpkg' {
        os.mv(m_path, os.join_path(dir, 'vpkg.json'))
    } 
}

fn (manifest PkgManifest) manipulate_version(@type string, state string) string {
    ver := manifest.version.all_before('-')
    mut ver_arr := ver.split('.')
    mut selected_idx := 0
    mut new_ver := ''

    match @type {
        'major' { selected_idx = 0 }
        'minor' { selected_idx = 1 }
        'patch' { selected_idx = 2 }
        else {}
    }

    for selected_idx > ver_arr.len-1 {
        ver_arr << '0'
    }

    ver_arr[selected_idx] = (ver_arr[selected_idx].int() + 1).str()

    for i := 0; i < ver_arr.len; i++ {
        if i > selected_idx {
            ver_arr[i] = '0'
        }
    }

    new_ver = ver_arr.join('.')

    if state.len != 0 {
        new_ver += '-${state}'
    } else {
        new_ver += manifest.version.all_after(ver)
    }

    return new_ver
}

fn (manifest PkgManifest) to_vmod() string {
    mut vmod := new_vmod()

    vmod.write('name', manifest.name, false)
    vmod.write('version', manifest.version, false)
    vmod.write_arr('deps', manifest.dependencies, false)
    vmod.close()

    return vmod.contents.str()
}

fn (manifest PkgManifest) to_vpkg_json() string {
    mut vpkg_json := new_vpkg_json()

    vpkg_json.write('name', manifest.name, false)
    vpkg_json.write('version', manifest.version, false)
    vpkg_json.write_arr('author', manifest.author, true)
    vpkg_json.write('repo', manifest.repo, false)
    vpkg_json.write_arr('dependencies', manifest.dependencies, true)
    vpkg_json.close()

    return vpkg_json.contents.str()
}

fn (manifest PkgManifest) is_exist(pkg_name string) bool {
    return pkg_name in manifest.dependencies
}

fn manifest_to_vmod(manifest PkgManifest, dir string) {
    mut vmod_file := os.create(os.join_path(dir, 'v.mod')) or { return }
    vmod_contents_str := manifest.to_vmod()

    vmod_file.write(vmod_contents_str)
    defer { vmod_file.close() }
}

fn manifest_to_vpkg(manifest PkgManifest, dir string) {
    mut vpkg_file := os.create(os.join_path(dir, 'vpkg.json')) or { return }
    vpkg_contents_str := manifest.to_vpkg_json()

    vpkg_file.write(vpkg_contents_str)
    defer { vpkg_file.close() }
}
