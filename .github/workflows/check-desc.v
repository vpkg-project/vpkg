module main

import os

const (
	readme_file = 'README.md'
	commands_header = '## Commands'
	code_mark = '```'
	vpkg_cmd = './vpkg'
)

fn main() {
	assert_readme_contains_help_output() or {
		println('Error: ${err}')
		exit(1)
	}
}

fn assert_readme_contains_help_output() ?bool {
	vpkg_output_readme := get_vpkg_output_from_readme() or {
		return error(err)
	}
	vpkg_output_vpkg := get_vpkg_output_from_vpkg() or {
		return error(err)
	}

	if vpkg_output_readme.len != vpkg_output_vpkg.len {
		readme_len := '- readme: ${vpkg_output_readme.len} lines'
		vpkg_len   := '- vpkg  : ${vpkg_output_vpkg.len} lines'

		return error('Outputs differ:\n${readme_len}\n${vpkg_len}')
	}

	output_len := vpkg_output_readme.len
	for i := 0; i < output_len; i++ {
		if vpkg_output_readme[i] != vpkg_output_vpkg[i] {
			readme_line := '- readme: ${vpkg_output_readme[i]}'
			vpkg_line   := '- vpkg  : ${vpkg_output_vpkg[i]}'

			return error('Lines differ:\n${readme_line}\n${vpkg_line}')
		}
	}

	return true // Stub value
}

fn get_vpkg_output_from_readme() ?[]string {
	readme_contents := os.read_file(readme_file) or {
		return error('Unable to read ${readme_file}')
	}

	commands_header_idx := readme_contents.index(commands_header) or {
		return error('Unable to find commands header')
	}

	mut start_idx := readme_contents.index_after(code_mark, commands_header_idx)
	if start_idx == -1 {
		return error('Unable to find start of `vpkg` output in readme')
	}
	start_idx += code_mark.len

	end_idx := readme_contents.index_after(code_mark, start_idx)
	if end_idx == -1 {
		return error('Unable to find end of `vpkg` output in readme')
	}

	vpkg_output := readme_contents[start_idx..end_idx].trim_space()
	vpkg_output_lines := vpkg_output.split_into_lines()

	if vpkg_output_lines.len == 0 {
		return error('Empty output from readme')
	}

	return vpkg_output_lines
}

fn get_vpkg_output_from_vpkg() ?[]string {
	vpkg_exec_result := os.exec(vpkg_cmd) or {
		return error('Unable to execute `vpkg`')
	}

	vpkg_output := vpkg_exec_result.output.trim_space()
	vpkg_output_lines := vpkg_output.split_into_lines()

	/*
	 * Check the case when output is "vpkg: not found",
	 * where len of vpkg_output_lines is 1.
	 */
	if vpkg_output_lines.len < 2 {
		return error('Empty output from `vpkg`')
	}

	return vpkg_output_lines
}
