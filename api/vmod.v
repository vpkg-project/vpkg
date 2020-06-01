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

// some of the code snippets taken from: https://github.com/vlang/v/blob/master/compiler/scanner.v

module api

import os

enum Lexeme {
    module_keyword lcbr rcbr labr comma rabr colon eof str name newline
}

struct VModPkgManifest {
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
    if !os.exists(vmod_path) {
        panic('v.mod not found.')
    }

    raw_vmod_contents := os.read_file(vmod_path) or {
        panic('cannot parse v.mod')
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

fn (mut s VModScanner) skip_whitespace() {
	for s.pos < s.text.len-1 && s.text[s.pos].is_space() {
		s.pos++
	}
}

fn is_newline(c byte) bool {
	return c == `\r` || c == `\n`
}

fn is_name_alpha(chr byte) bool {
    return chr.is_letter() || chr == `_`
}

fn (mut s VModScanner) create_string() string {
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
		lit = s.text[start..end]
	}
	return lit
}

fn (mut s VModScanner) create_identifier() string {
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
	name := s.text[start..s.pos]
	s.pos--
	return name
}

fn get_array_contents(tokens []Token, start_pos int) []string {
    mut inside_array := true
    mut contents := []string{}

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

    match t_type {
        .module_keyword { token_type = 'module_keyword' }
        .lcbr { token_type = 'lcbr' }
        .rcbr { token_type = 'rcbr' }
        .labr { token_type = 'labr' }
        .rabr { token_type = 'rabr' }
        .colon { token_type = 'colon' }
        .eof { token_type = 'eof' }
        .str { token_type = 'str' }
        .name { token_type = 'name' }
        else { token_type = 'unknown' }
    }

    return token_type
}

fn (mut s VModScanner) scan() Token {
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

    char_ := s.text[s.pos]
    mut next_char := `\0`

    if s.pos + 1 < s.text.len {
        next_char = s.text[s.pos + 1]
    }

    if is_name_alpha(char_) {
        name := s.create_identifier()
        next_ := if s.pos + 1 < s.text.len { s.text[s.pos + 1] } else { `\0` }

        if s.inside_text {
            if next_ == `\'` {
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

    match char_ {
        `{` {
            if s.inside_text { return s.scan() }
            return tokenize(.lcbr, '')
        }
        `}` {
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
        }
        `\'` { return tokenize(.str, s.create_string()) }
        `[` { return tokenize(.labr, '') }
        `]` { return tokenize(.rabr, '') }
        `,` { return tokenize(.comma, '') }
        `\r` {
            if next_char == `\n` {
                s.pos++
                return tokenize(.newline, '')
            }
        }
        `\n` { return tokenize(.newline, '') }
        `:` { return tokenize(.colon, '') }
        else { return tokenize(.eof, '') }
    }

    return tokenize(.eof, '')
}

fn (mut s VModScanner) parse() VModPkgManifest {
    mut tokens := []Token{}
    mut pkg_info := VModPkgManifest{}

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

                match current_tokens.val {
                    'name' { pkg_info.name = value }
                    'version' { pkg_info.version = value }
                    else{ continue }
                }
            }

            if token_type(next_next.@type) == 'labr' {
                match current_tokens.val {
                    'deps' { pkg_info.deps = get_array_contents(tokens, i+2) }
                    else { continue }
                }
            }
        }

        if c_token_type == 'rcbr' || n_token_type == 'eof' {
            has_started = false
        }
    }

    return pkg_info
}

pub fn open_vmod(vmod_path string) PkgManifest {
    mut sc := new_scanner(vmod_path)
    parsed := sc.parse()

    return PkgManifest{
        name: parsed.name,
        version: parsed.version,
        dependencies: parsed.deps
    }
}
