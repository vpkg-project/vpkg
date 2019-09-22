module main

import (
    vargs
    os
)

const (
    Version = '0.4.1'
    GlobalModulesDir = '${os.home_dir()}/.vmodules'
)

fn new_vpkg(dir string) Vpkg {
    _argv := vargs.parse(os.args, 1)

    mut instance := Vpkg{
        command: _argv.command, 
        options: _argv.options, 
        unknown: _argv.unknown, 
        dir: dir,
        manifest_file_path: get_manifest_file_path(dir),
        is_global: false
    }

    instance.manifest = load_manifest_file(instance.dir)

    return instance
}

fn (vpkg mut Vpkg) run() {
    vpkg.is_global = 'g' in vpkg.options || 'global' in vpkg.options

    switch vpkg.command {
        case 'get':
            vpkg.get_packages(vpkg.unknown)
        case 'help':
            vpkg.show_help()
        case 'info':
            vpkg.show_package_information()
        case 'init':
            vpkg.create_manifest_file()
        case 'install':
            vpkg.install_packages(vpkg.dir)
        case 'remove':
            vpkg.remove_packages(vpkg.unknown)
        case 'migrate':
            if vpkg.unknown[0] == 'manifest' {
                vpkg.migrate_manifest()
            } else {
                vpkg.show_help()
            }
        case 'update':
            vpkg.update_packages()
        case 'version':
            vpkg.show_version()
        default:
            vpkg.show_help()
    }
}

fn main() {
    mut app := new_vpkg(os.getwd())
    
    app.run()
}
