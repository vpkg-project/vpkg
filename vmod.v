// some of the code snippets taken from: https://github.com/vlang/v/blob/master/compiler/scanner.v

module main

import os

enum TokenTypes {
    module_keyword lcbr rcbr labr comma rabr colon eof str name newline c_return
}

struct VModPkgInfo {
mut:
    name string
    version string
    deps []string
}

struct VModScanner {
mut:
    pos int
    text string
    path string
    inside_text bool
    started bool
}

struct ResolveScan {
    @type TokenTypes
    val string
}

fn resolve(t_type TokenTypes, val string) ResolveScan {
    return ResolveScan{t_type, val}
}

fn (s mut VModScanner) ident_string() string {
	mut start := s.pos
	s.inside_text = false
	slash := `\\`
	for {
		s.pos++
		if s.pos >= s.text.len {
			break
		}
		c := s.text[s.pos]
		prevc := s.text[s.pos - 1]

		if c == `\'` && (prevc != slash || (prevc == slash && s.text[s.pos - 2] == slash)) {
			break
		}
	}
	mut lit := ''
	if s.text[start] == `\'` {
		start++
	}
	mut end := s.pos
	if s.inside_text {
		end++
	}
	if start > s.pos{}
	else {
		lit = s.text.substr(start, end)
	}
	return lit
}


fn new_scanner(vmod_path string) VModScanner {
    if !os.file_exists(vmod_path) {
        panic('v.mod not found.')
    }

    raw_vmod_contents := os.read_file(vmod_path) or {
        panic('cannot parse v.mod')
        return VModScanner{}
    }

    scanner := VModScanner{
        pos: 0,
        path: vmod_path,
        text: raw_vmod_contents
    }

    return scanner
}

fn (s mut VModScanner) skip_whitespace() {
	for s.pos < s.text.len && s.text[s.pos].is_white() {
		s.pos++
	}
}

fn is_name_alpha(chr byte) bool {
    return chr.is_letter() || chr == `_`
}

fn (s mut VModScanner) ident_name() string {
	start := s.pos
	for {
		s.pos++
		if s.pos >= s.text.len {
			break
		}
		c := s.text[s.pos]
		if !is_name_alpha(c) && !c.is_digit() {
			break
		}
	}
	name := s.text.substr(start, s.pos)
	s.pos--
	return name
}

fn is_nl(c byte) bool {
	return c == `\r` || c == `\n`
}

fn get_array_contents(ast []ResolveScan, start_pos int) []string {
    mut inside_array := true
    mut contents := []string

    for i := start_pos; inside_array != false; i++ {
        if ast_type(ast[i].@type) == 'str' {
            println(ast[i].val)

            contents << ast[i].val
        }

        if ast_type(ast[i+1].@type) == 'rabr' {
            inside_array = false
        }
    }

    return contents
}

fn (s mut VModScanner) scan() ResolveScan {
    if s.started && s.pos != s.text.len-1 {
        s.pos++
    }

    s.started = true

    if s.pos == s.text.len-1 {
        s.started = false
    }

    if !s.inside_text {
        s.skip_whitespace()
    }

    s.skip_whitespace()

    char := s.text[s.pos]
    mut next_char := `\0`

    if s.pos + 1 < s.text.len {
        next_char = s.text[s.pos + 1]
    }

    if is_name_alpha(char) {
        name := s.ident_name()
        _next := if s.pos + 1 < s.text.len { s.text[s.pos + 1] } else { `\0` }

        if s.inside_text {
            if _next == `\'` {
                s.pos++
                s.inside_text = false
            }
        }

        if s.pos == 0 && next_char == ` ` {
			s.pos++
		}

        if name == 'Module' {
            return resolve(.module_keyword, name)
        } else {
            return resolve(.name, name)
        }
    }

    switch char {
        case `{`:
            if s.inside_text { return s.scan() }
            return resolve(.lcbr, '')
        case `}`:
            if s.inside_text {
                s.pos++

                if s.text[s.pos] == `\'` {
                    s.inside_text = false
                    return resolve(.str, '')
                }
                return resolve(.str, s.ident_string())
            }
            else {
                return resolve(.rcbr, '')
            }
        case `\'`:
            return resolve(.str, s.ident_string())
        case `[`:
            return resolve(.labr, '')
        case `]`:
            return resolve(.rabr, '')
        case `,`:
            return resolve(.comma, '')
        case `\r`:
            if next_char == `\n` {
                s.pos++
                return resolve(.newline, '')
            }
        case `\n`:
            return resolve(.newline, '')
        case `:`:
            return resolve(.colon, '')
    }

    return resolve(.eof, '')
}

fn ast_type(t_type TokenTypes) string {
    mut ast_type := 'name'

    switch t_type {
        case TokenTypes.module_keyword:
            ast_type = 'module_keyword'
        case TokenTypes.lcbr:
            ast_type = 'lcbr'
        case TokenTypes.rcbr:
            ast_type = 'rcbr'
        case TokenTypes.labr:
            ast_type = 'labr'
        case TokenTypes.rabr:
            ast_type = 'rabr'
        case TokenTypes.colon:
            ast_type = 'colon'
        case TokenTypes.eof:
            ast_type = 'eof'
        case TokenTypes.str:
            ast_type = 'str'
        case TokenTypes.name:
            ast_type = 'name'
    }

    return ast_type
}

fn (s mut VModScanner) parse() VModPkgInfo {
    mut ast := []ResolveScan
    mut pkg_info := VModPkgInfo{}

    mut has_started := false

    for i := -1; s.pos != s.text.len-1; i++ {
        ast << s.scan()
    }

    if ast[0].@type != .module_keyword {
        panic('incorrect v.mod')
    }

    if ast_type(ast[0].@type) == 'module_keyword' && ast_type(ast[1].@type) == 'lcbr' {
        has_started = true
    }

    for i := 0; has_started != false; i++ {
        current_ast := ast[i]
        next_ast := if i+1 < ast.len { ast[i+1] } else { ResolveScan{} }

        c_ast_type := ast_type(current_ast.@type)
        n_ast_type := ast_type(next_ast.@type)

        if c_ast_type == 'name' && n_ast_type == 'colon' {
            next_next := ast[i+2]
            
            if ast_type(next_next.@type) == 'str' {
                value := next_next.val

                switch current_ast.val {
                    case 'name':
                        pkg_info.name = value
                    case 'version':
                        pkg_info.version = value
                }
            }

            if ast_type(next_next.@type) == 'labr' {
                switch current_ast.val {
                    case 'deps':
                        pkg_info.deps = get_array_contents(ast, i+2)
                }
            }
        }

        if c_ast_type == 'rcbr' && n_ast_type == 'eof' {
            has_started = false
        }
    }

    return pkg_info
}



pub fn open_vmod(vmod_path string) PkgInfo {
    mut sc := new_scanner(vmod_path)
    parsed := sc.parse()

    return PkgInfo{
        name: parsed.name,
        version: parsed.version,
        dependencies: parsed.deps
    }
}