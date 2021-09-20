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

pub struct MercurialProvider {
pub:
	domains   []string
	protocols []string = ['http', 'https', 'hg']
mut:
	output_dir string
}

fn (hgp &MercurialProvider) is_valid_hg(url &urllib.URL) ?string {
	hg_dir := os.join_path(url.path)

	// file:// is supported for now
	if url.scheme != 'file' {
		return error('file:// URLs are only supported for now.')
	} else if !os.exists(hg_dir) {
		return error('hg folder does not exist')
	}

	return hg_dir
}

pub fn (hgp &MercurialProvider) fetch(url &urllib.URL, folder_name string) ?string {
	// folder_name sanitation should be done before it reaches to the providers
	// if pkg_name.starts_with('v-') { pkg_name.all_after('v-') } else { pkg_name }
	branch := url.fragment
	clone_url := url.str().all_before('#')
	clone_dir := os.join_path(hgp.output_dir, folder_name)

	// module should be checked before installing?
	// if os.exists(clone_dir) {
	// 		delete_package_contents(clone_dir)
	// }

	hg_result := os.execute('hg clone --branch $branch --quiet --depth 1 $clone_url $clone_dir')
	if hg_result.exit_code != 0 {
		return error_with_code(hg_result.output, hg_result.exit_code)
	}

	return clone_dir
}

pub fn (hgp &MercurialProvider) get_version(url &urllib.URL) string {
	hg_dir := hgp.is_valid_hg(url) or { return '' }

	hg_result := os.execute('hg --cwd $hg_dir identify')
	if hg_result.exit_code != 0 {
		return ''
	}

	return hg_result.output
}

pub fn (hgp &MercurialProvider) update(url &urllib.URL) ? {
	hg_dir := hgp.is_valid_hg(url) ?

	hg_result := os.execute('hg --cwd $hg_dir fetch')
	if hg_result.exit_code != 0 {
		return error_with_code(hg_result.output, hg_result.exit_code)
	}

	hg_result2 := os.execute('hg --cwd $hg_dir pull -u')
	if hg_result2.exit_code != 0 {
		return error_with_code(hg_result2.output, hg_result2.exit_code)
	}
}

pub fn (hgp &MercurialProvider) remove(url &urllib.URL) ? {
	_ = hgp.is_valid_hg(url) ?
	os.rmdir_all(url.path) ?
	os.rm(url.path) ?
}
