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

module providers

import net.urllib
import os

pub struct GitProvider {
pub:
	domains   []string = ['github.com', 'bitbucket.com', 'gitlab.com', 'git.sr.ht']
	protocols []string = ['http', 'https', 'git']
mut:
	output_dir string
}

fn (gp &GitProvider) is_valid_git(url &urllib.URL) ?string {
	git_dir := os.join_path(url.path, '.git')

	// file:// is supported for now
	if url.scheme != 'file' {
		return error('file:// URLs are only supported for now.')
	} else if !os.exists(git_dir) {
		return error('git folder does not exist')
	}

	return git_dir
}

pub fn (gp &GitProvider) fetch(url &urllib.URL, folder_name string) ?string {
	// folder_name sanitation should be done before it reaches to the providers
	// if pkg_name.starts_with('v-') { pkg_name.all_after('v-') } else { pkg_name }
	clone_url := url.str().all_before('#')
	clone_dir := os.join_path(gp.output_dir, folder_name)
	branch := if url.fragment.len != 0 { '--branch $url.fragment' } else { '' }

	// module should be checked before installing?
	// if os.exists(clone_dir) {
	// 		delete_package_contents(clone_dir)
	// }

	git_result := os.execute('git clone $clone_url $clone_dir $branch --quiet --depth 1')
	if git_result.exit_code != 0 {
		return error_with_code(git_result.output, git_result.exit_code)
	}

	return clone_dir
}

pub fn (gp &GitProvider) get_version(url &urllib.URL) string {
	git_dir := gp.is_valid_git(url) or { return '' }
	git_result := os.execute('git --git-dir $git_dir rev-parse HEAD')
	if git_result.exit_code != 0 {
		return ''
	}

	return git_result.output.trim_space()
}

pub fn (gp &GitProvider) update(url &urllib.URL) ? {
	git_dir := gp.is_valid_git(url) ?
	git_result := os.execute('git --git-dir $git_dir pull')
	if git_result.exit_code != 0 {
		return error_with_code(git_result.output, git_result.exit_code)
	}
}

pub fn (gp &GitProvider) remove(url &urllib.URL) ? {
	gp.is_valid_git(url) ?
	os.rmdir_all(url.path) ?
	os.rm(url.path) ?
}
