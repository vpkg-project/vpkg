module api

import (
    os
    filepath
)

const (
    Version = '0.7'
    GlobalModulesDir = os.home_dir() + '.vmodules'
)

pub struct Vpkg {
pub mut:
    command string
    options map[string]string
    unknown []string
    dir string
    install_dir string
    manifest_file_path string
    manifest PkgManifest
    is_global bool
    sources []string
}

pub fn new(dir string) Vpkg {
    instance := Vpkg{
        dir: dir,
        manifest_file_path: get_manifest_file_path(dir),
        install_dir: filepath.join(dir, 'modules')
        is_global: false,
        manifest: load_manifest_file(dir)
    }

    return instance
}

pub fn (vpkg mut Vpkg) run(args []string) {
	_argv := vargs_parse(args, 0)
	vpkg.command =  _argv.command
    vpkg.options = _argv.options 
    vpkg.unknown = _argv.unknown
    vpkg.is_global = 'g' in vpkg.options || 'global' in vpkg.options

    match vpkg.command {
        'get' { vpkg.get_packages(vpkg.unknown, true) }
        'help' { vpkg.show_help() }
        'info' { vpkg.show_package_information() }
        'init' { vpkg.create_manifest_file() }
        'install' { vpkg.install_packages(vpkg.dir) }
        'remove' { vpkg.remove_packages(vpkg.unknown) }
        'migrate' { if vpkg.unknown[0] == 'manifest' {vpkg.migrate_manifest()} else {vpkg.show_help()} }
        'update' { vpkg.update_packages() }
        'version' { vpkg.show_version() }
        'test' { vpkg.test_package() }
        'release' { vpkg.release_module_to_git() }
        else { vpkg.show_help() }
    }
}