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

struct FetchMethod {
    download_url string
    dir          string
mut:
    args         []string
}

fn (fm FetchMethod) dl_package(method string) InstalledPackage {
    match method {
        'git' { return fm.git_clone() }
        'hg'  { return fm.hg_clone()  }
        else  {
            eprintln('No methods matched.')
            return InstalledPackage{}
        }
    }
}

fn (fm FetchMethod) update_package(method string) string {
    match method {
        'git' { return fm.git_pull() }
        'hg'  { return fm.hg_pull () }
        else  {
            eprintln('No methods matched.')
            return ''
        }
    }
} 

fn (fm FetchMethod) fetch_update(method string) string {
    match method {
        'git' { return fm.git_fetch() }
        'hg'  { return fm.hg_fetch () }
        else  {
            eprintln('No methods matched.')
            return ''
        }
    }
}

fn (fm FetchMethod) check_version(method string) string {
    match method {
        'git' { return fm.git_latest_commit() }
        'hg'  { return fm.hg_latest_commit () }
        else  {
            eprintln('No methods matched.')
            return ''
        }
    }
}

// git

fn (fm FetchMethod) git_clone() InstalledPackage {
    pkg_name  := package_name(fm.download_url)
    dir_name  := if pkg_name.starts_with('v-') { pkg_name.all_after('v-') } else { pkg_name }
    branch    := if fm.download_url.all_after('#') != fm.download_url { fm.download_url.all_after('#') } else { 'master' }
    clone_url := fm.download_url.all_before('#')
    clone_dir := os.join_path(fm.dir, dir_name)

    if os.exists(clone_dir) {
        delete_package_contents(clone_dir)
    }

    git_clone := os.exec('git clone ${clone_url} ${clone_dir} --branch ${branch} --quiet --depth 1') or {
        eprintln('Git clone error')
        return InstalledPackage{}
    }

    println(git_clone.output)
    pkg_manifest := load_manifest_file(clone_dir)

    return InstalledPackage{
        name         : pkg_name
        path         : clone_dir
        version      : if pkg_manifest.version.len != 0 { pkg_manifest.version } else { fm.git_latest_commit() }
        url          : fm.download_url
        latest_commit: fm.git_latest_commit()
        method       : 'git'
    }
}

fn (fm FetchMethod) git_fetch() string {
    cmd := os.exec('git -C ${fm.dir} fetch') or { return '' }
    return cmd.output
}

fn (fm FetchMethod) git_pull() string {
    cmd := os.exec('git -C ${fm.dir} pull') or { return '' }
    return cmd.output
}

fn (fm FetchMethod) git_latest_commit() string {
    pkg_name  := package_name(fm.download_url)
    dir_name  := if pkg_name.starts_with('v-') { pkg_name.all_after('v-') } else { pkg_name }
    clone_dir := '${fm.dir}/${dir_name}'

    cmd := os.exec('git --git-dir ${clone_dir}/.git log --pretty=format:%H -n 1') or { return '' }

    return cmd.output
}

// hg

fn (fm FetchMethod) hg_clone() InstalledPackage {
    pkg_name  := package_name(fm.download_url)
    dir_name  := if pkg_name.starts_with('v-') { pkg_name.all_after('v-') } else { pkg_name }
    branch    := if fm.download_url.all_after('#') != fm.download_url { fm.download_url.all_after('#') } else { 'master' }
    clone_url := fm.download_url.all_before('#')
    clone_dir := os.join_path(fm.dir, dir_name)

    if os.exists(clone_dir) {
        delete_package_contents(clone_dir)
    }

    hg_clone := os.exec('hg clone ${clone_url} ${clone_dir} --branch ${branch} --quiet') or {
        eprintln('Mercurial clone error')
        return InstalledPackage{}
    }

    println(hg_clone.output)
    pkg_manifest := load_manifest_file(clone_dir)

    return InstalledPackage{
        name         : pkg_name
        path         : clone_dir
        version      : if pkg_manifest.version.len != 0 { pkg_manifest.version } else { fm.hg_latest_commit() }
        url          : fm.download_url
        latest_commit: fm.hg_latest_commit()
        method       : 'hg'
    }
}

fn (fm FetchMethod) hg_fetch() string {
    cmd := os.exec('hg pull -R ${fm.dir}') or { return '' }

    return cmd.output
}

fn (fm FetchMethod) hg_pull() string {
    cmd := os.exec('hg pull -u -R ${fm.dir}') or { return '' }

    return cmd.output
}

fn (fm FetchMethod) hg_latest_commit() string {
    pkg_name  := package_name(fm.download_url)
    dir_name  := if pkg_name.starts_with('v-') { pkg_name.all_after('v-') } else { pkg_name }
    clone_dir := '${fm.dir}/${dir_name}'

    cmd := os.exec('hg log --template "{node}" ${clone_dir}') or { return '' }

    return cmd.output
}

// svn

fn (fm FetchMethod) svn_checkout() InstalledPackage {
    pkg_name  := package_name(fm.download_url)
    dir_name  := if pkg_name.starts_with('v-') { pkg_name.all_after('v-') } else { pkg_name }
    branch    := if fm.download_url.all_after('#') != fm.download_url { fm.download_url.all_after('#') } else { 'master' }
    clone_url := fm.download_url.all_before('#')
    clone_dir := os.join_path(fm.dir, dir_name)

    if os.exists(clone_dir) {
        delete_package_contents(clone_dir)
    }

    svn_clone := os.exec('svn checkout ${clone_url} ${clone_dir} --revision ${branch} --depth 1 --quiet') or {
        eprintln('Mercurial clone error')
        return InstalledPackage{}
    }

    println(svn_clone.output)
    pkg_manifest := load_manifest_file(clone_dir)

    return InstalledPackage{
        name         : pkg_name
        path         : clone_dir
        version      : if pkg_manifest.version.len != 0 { pkg_manifest.version } else { fm.svn_latest_commit() }
        url          : fm.download_url
        latest_commit: fm.svn_latest_commit()
        method       : 'svn'
    }
}

fn (fm FetchMethod) svn_fetch() string {
    return fm.svn_pull()
}

fn (fm FetchMethod) svn_pull() string {
    cmd := os.exec('svn update ${fm.dir}') or { return '' }
    return cmd.output
}

fn (fm FetchMethod) svn_latest_commit() string {
    return ''
}
