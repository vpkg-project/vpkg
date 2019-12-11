module api

import (
	filepath
	os
)

struct FetchMethod {
	download_url string
    dir string
mut:
    args []string
}

fn (fm FetchMethod) dl_package(method string) InstalledPackage {
	match method {
		'git' { return fm.git_clone() }
		else {
			eprintln('No methods matched.')
			return InstalledPackage{}
		}
	}
}

fn (fm FetchMethod) update_package(method string) string {
	match method {
		'git' { return fm.git_pull() }
		else {
			eprintln('No methods matched.')
			return ''
		}
	}
} 

fn (fm FetchMethod) fetch_update(method string) string {
	match method {
		'git' { return fm.git_fetch() }
		else {
			eprintln('No methods matched.')
			return ''
		}
	}
}

fn (fm FetchMethod) check_version(method string) string {
	match method {
		'git' { return fm.git_latest_commit() }
		else {
			eprintln('No methods matched.')
			return ''
		}
	}
}

// git

fn (fm FetchMethod) git_clone() InstalledPackage {
	pkg_name := package_name(fm.download_url)
    dir_name := if pkg_name.starts_with('v-') { pkg_name.all_after('v-') } else { pkg_name }
    branch := if fm.download_url.all_after('#') != fm.download_url { fm.download_url.all_after('#') } else { 'master' }
    clone_url := fm.download_url.all_before('#')
    clone_dir := filepath.join(fm.dir, dir_name)

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
        name: pkg_name,
        path: clone_dir,
        version: if pkg_manifest.version.len != 0 { pkg_manifest.version } else { fm.git_latest_commit() },
		url: fm.download_url,
		latest_commit: fm.git_latest_commit(),
		method: 'git'
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
	pkg_name := package_name(fm.download_url)
    dir_name := if pkg_name.starts_with('v-') { pkg_name.all_after('v-') } else { pkg_name }
	clone_dir := '${fm.dir}/${dir_name}'

	cmd := os.exec('git --git-dir ${clone_dir}/.git log --pretty=format:%H -n 1') or { return '' }

    return cmd.output
}