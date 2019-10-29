module api

import (
    os
)

const (
    Version = '0.5.3'
    GlobalModulesDir = '${os.home_dir()}/.vmodules'
)

pub fn new_vpkg(dir string) Vpkg {
    mut instance := Vpkg{
        dir: dir,
        manifest_file_path: get_manifest_file_path(dir),
        is_global: false
    }

    instance.manifest = load_manifest_file(instance.dir)

    return instance
}

pub fn (vpkg mut Vpkg) run(args []string) {
	_argv := vargs_parse(args, 0)
	vpkg.command =  _argv.command
    vpkg.options = _argv.options 
    vpkg.unknown = _argv.unknown
    vpkg.is_global = 'g' in vpkg.options || 'global' in vpkg.options

    match vpkg.command {
        'get' { vpkg.get_packages(vpkg.unknown) }
        'help' { vpkg.show_help() }
        'info' { vpkg.show_package_information() }
        'init' { vpkg.create_manifest_file() }
        'install' { vpkg.install_packages(vpkg.dir) }
        'remove' { vpkg.unknown }
        'migrate' { if vpkg.unknown[0] == 'manifest' {vpkg.migrate_manifest()} else {vpkg.show_help()} }
        'update' { vpkg.update_packages() }
        'version' { vpkg.show_version() }
        else { vpkg.show_help() }
    }
}