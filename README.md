# vpkg 
vpkg is a package manager written on [V](https://github.com/vlang/v) for V.

## Features
Bringing the best of dependency management on V.
- **Decentralized.** Download and use packages from other sources aside from VPM and vpkg registry.
- **Easy to use.** Set-up, use, and master the commands of vpkg CLI within minutes.
- **Fast.** It can be run from the low-spec PC to the fastest supercomputers.
- **Interoperable.** It supports `v.mod`, and `.vpm.json` for reading package manifests and managing dependencies.
- **Light.** Weighs only at < 300kb so it can be used in devices with tight storage or in low network conditions.
- **Reliable.** It uses a lockfile mechanism to ensure that all your dependencies work across all of your machines.

## Running your own registry
vpkg's own [registry server](https://github.com/vpkg-project/registry) is a perfect template to start running your own registry server. Just modify `registry.json` and use any http or web library of your choice to get up and running.

## Commands
```
Usage: vpkg <COMMAND> [ARGS...] [options]

COMMANDS

get [packages]                             Fetch and installs packages from the registry or the git repo.
help                                       Prints this help message.
info                                       Show project's package information.
init [--format=vpkg|vmod]                  Creates a package manifest file into the current directory. Defaults to "vpkg".
install                                    Reads the package manifest file and installs the necessary packages.
migrate manifest [--format=vpkg|vmod]      Migrate manifest file to a specified format.
remove [packages]                          Removes packages
update                                     Updates packages.
version                                    Prints the version of this program.

OPTIONS

--global, -g                               Installs the modules/packages into the `.vmodules` folder.
--force                                    Force download the packages.
```

## vpkg API
vpkg can now be imported as a separate module in which you will be able to utilize all vpkg's features into your own programs. It's especially more useful if you want to be able to create your scripts for your project to setup your dependencies without compiling and installing a separate CLI.

```golang
// install.v
module main

import vpkg.api

fn main() {
	mut inst := api.new_vpkg('.')
	inst.run(['install'])

	os.system('rm ${os.executable()}')
}

```

```sh
$ v run install.v
Installing packages
Fetching nedpals.vargs

vargs@fc193513733c2ed99467f5d903a824ea9087ed52
1 package was installed successfully.
```

## TODO
- ability to publish and ~~search~~ packages in VPM and VPKG registry.
- unified logging interface

## Installation
- Clone the repo.
- Build it from source.

## Building from Source
```
git clone https://github.com/vpkg-project/vpkg.git
cd vpkg/
v -prod .
```


## Copyright
(C) 2019 [Ned Palacios](https://github.com/nedpals)
