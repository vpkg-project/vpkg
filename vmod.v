// some of the code snippets taken from: https://github.com/vlang/v/blob/mtokenser/compiler/scanner.v

module main

import os

enum Lexeme {
    module_keyword lcbr rcbr labr comma rabr colon eof str name newline
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

struct Token {
    @type Lexeme
    val string
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

fn tokenize(t_type Lexeme, val string) Token {
    return Token{t_type, val}
}

fn (s mut VModScanner) skip_whitespace() {
	for s.pos < s.text.len && s.text[s.pos].is_white() {
		s.pos++
	}
}

fn is_newline(c byte) bool {
	return c == `\r` || c == `\n`
}

fn is_name_alpha(chr byte) bool {
    return chr.is_letter() || chr == `_`
}

fn (s mut VModScanner) create_string() string {
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

fn (s mut VModScanner) create_identifier() string {
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

fn get_array_contents(tokens []Token, start_pos int) []string {
    mut inside_array := true
    mut contents := []string

    for i := start_pos; inside_array != false; i++ {
        if token_type(tokens[i].@type) == 'str' {
            contents << tokens[i].val
        }

        if token_type(tokens[i+1].@type) == 'rabr' {
            inside_array = false
        }
    }

    return contents
}

fn token_type(t_type Lexeme) string {
    mut token_type := 'name'

    switch t_type {
        case Lexeme.module_keyword:
            token_type = 'module_keyword'
        case Lexeme.lcbr:
            token_type = 'lcbr'
        case Lexeme.rcbr:
            token_type = 'rcbr'
        case Lexeme.labr:
            token_type = 'labr'
        case Lexeme.rabr:
            token_type = 'rabr'
        case Lexeme.colon:
            token_type = 'colon'
        case Lexeme.eof:
            token_type = 'eof'
        case Lexeme.str:
            token_type = 'str'
        case Lexeme.name:
            token_type = 'name'
    }

    return token_type
}

fn (s mut VModScanner) scan() Token {
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
        name := s.create_identifier()
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
            return tokenize(.module_keyword, name)
        } else {
            return tokenize(.name, name)
        }
    }

    switch char {
        case `{`:
            if s.inside_text { return s.scan() }
            return tokenize(.lcbr, '')
        case `}`:
            if s.inside_text {
                s.pos++

                if s.text[s.pos] == `\'` {
                    s.inside_text = false
                    return tokenize(.str, '')
                }
                return tokenize(.str, s.create_string())
            }
            else {
                return tokenize(.rcbr, '')
            }
        case `\'`:
            return tokenize(.str, s.create_string())
        case `[`:
            return tokenize(.labr, '')
        case `]`:
            return tokenize(.rabr, '')
        case `,`:
            return tokenize(.comma, '')
        case `\r`:
            if next_char == `\n` {
                s.pos++
                return tokenize(.newline, '')
            }
        case `\n`:
            return tokenize(.newline, '')
        case `:`:
            return tokenize(.colon, '')
    }

    return tokenize(.eof, '')
}

fn (s mut VModScanner) parse() VModPkgInfo {
    mut tokens := []Token
    mut pkg_info := VModPkgInfo{}

    mut has_started := false

    for i := -1; s.pos != s.text.len-1; i++ {
        tokens << s.scan()
    }

    if tokens[0].@type != .module_keyword {
        panic('incorrect v.mod')
    }

    if token_type(tokens[0].@type) == 'module_keyword' && token_type(tokens[1].@type) == 'lcbr' {
        has_started = true
    }

    for i := 0; has_started != false; i++ {
        current_tokens := tokens[i]
        next_tokens := if i+1 < tokens.len { tokens[i+1] } else { Token{} }

        c_token_type := token_type(current_tokens.@type)
        n_token_type := token_type(next_tokens.@type)

        if c_token_type == 'name' && n_token_type == 'colon' {
            next_next := tokens[i+2]
            
            if token_type(next_next.@type) == 'str' {
                value := next_next.val

                switch current_tokens.val {
                    case 'name':
                        pkg_info.name = value
                    case 'version':
                        pkg_info.version = value
                }
            }

            if token_type(next_next.@type) == 'labr' {
                switch current_tokens.val {
                    case 'deps':
                        pkg_info.deps = get_array_contents(tokens, i+2)
                }
            }
        }

        if c_token_type == 'rcbr' || n_token_type == 'eof' {
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