# vpkg 
vpkg is a package manager written on [V](https://github.com/vlang/v) for V.

## Features
vpkg's approach is to incorporate the ideas taken from centralized and decentralized package managers.
- Centralized, popular packages are being listed on [VPM](https://vpm.vlang.io) and on to a single [`registry.json`](https://github.com/v-pkg/registry/tree/master/registry.json) file.
- Uses a single, JSON file for storing package information as well as it's dependencies. (In this case, [`vpkg.json`](vpkg.json))
- Packages stored from `registry.json` file can be obtained through a simple `vpkg get [package name]` while the rest uses regular Git URLs.
- Support for multiple package manifests (`v.mod`, and `vpkg.json`).
- Support for custom package registries/sources.


## Running your own registry
vpkg's own [registry server](https://github.com/v-pkg/registry) is a perfect template to start running your own registry server. Just modify `registry.json` and use any http or web library of your choice to get up and running.

## Commands
```
VPkg 0.5
An alternative package manager for V.

USAGE

vpkg <COMMAND> [ARGS...] [options]

COMMANDS

get [packages]                             Fetch and installs packages from the registry or the git repo.
help                                       Prints this help message.
info                                       Show project's package information.
init [--format=vpkg|vmod]                  Creates a package manifest file into the current directory. Defaults to "vpkg".
install                                    Reads the package manifest file and installs the necessary packages.
migrate manifest [--format=vpkg|vmod]      Migrate manifest file to a specified format.
remove [packages]                          Removes packages
update                                     Updates packages.
version                                    Prints the Version of this program.

OPTIONS

--global, -g                               Installs the modules/packages into the `.vmodules` folder.
--force                                    Force download the packages
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
Fetching package from vpm...

vargs@fc193513733c2ed99467f5d903a824ea9087ed52
1 package was installed successfully.
```

## TODO
- ability to publish and search packages in VPM and VPKG registry.
- recursive installation of dependencies of packages.
- unified logging interface

## Installation
- Clone the repo.
- Download and install [v-args](https://github.com/nedpals/vargs) and place it into the folder where your vpkg source code is located.
- Build it from source.

## Building from Source
```
git clone https://github.com/v-pkg/vpkg.git
cd vpkg/
v -prod .
```


## Copyright
(C) 2019 [Ned Palacios](https://github.com/nedpals)
