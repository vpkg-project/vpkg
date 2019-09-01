# vpkg 
vpkg is a package manager written on [V](https://github.com/vlang/v) for V.

## Features
vpkg's approach is to incorporate the ideas taken from centralized and decentralized package managers.
- Centralized, popular packages are being listed on [VPM](https://vpm.vlang.io) and on to a single [`registry.json`](https://github.com/v-pkg/registry/tree/master/registry.json) file.
- Uses a single, JSON file for storing package information as well as it's dependencies. (In this case, [`.vpkg.json`](.vpkg.json))
- Packages stored from `registry.json` file can be obtained through a simple `vpkg get [package name]` while the rest uses regular Git URLs.
- Support for multiple package manifests (`v.mod`, `.vpm.json`, and `.vpkg.json`).
- Support for custom package registries/sources.

## Custom Registry
Starting with VPkg `0.4.1`, you can now use your own custom sources to download your favorite modules. VPkg will detect a `registry.json` file from the registry to parse and scan if the name is present. Simply add a `sources` field to your `.vpkg.json` file and you're good to go!
```json
{
    "name": "vpkg",
    "version": "0.1.0",
    "author": ["Name <example@email.com>"],
    "repo": "https://github.com/nedpals/vpkg",
    "sources": ["https://example-vpkg-registry.com", "https://vpkg-reg.com/registry"],
    "dependencies": [
        "https://github.com/nedpals/v-args.git"
    ]
}
```

### Running your own
VPkg's own [registry server](https://github.com/v-pkg/registry) is a perfect template to start running your own registry server. Just modify `registry.json` and use any http or web library of your choice to get up and running.

## Commands
```
VPkg 0.3
An alternative package manager for V.

USAGE

vpkg <COMMAND> [ARGS...] [options]

COMMANDS

get [packages]                     Fetch and installs packages from the registry or the git repo.
help                               Prints this help message.
info                               Show project's package information.
init [--format=vpkg|vmod]          Creates a package manifest file into the current directory. Defaults to "vpkg".
install                            Reads the package manifest file and installs the necessary packages.
remove [packages]                  Removes packages
update                             Updates packages.
version                            Prints the Version of this program.

OPTIONS

--global, -g                       Installs the modules/packages into the `.vmodules` folder.
```

## TODO
- ability to publish and search packages in VPM and VPKG registry.
- recursive installation of dependencies of packages.
- unified logging interface

## Installation
- Clone the repo.
- Download and install [v-args](https://github.com/nedpals/v-args) and place it into the folder where your vpkg source code is located.
- Build it from source.

## Building from Source
```
git clone https://github.com/v-pkg/vpkg.git
cd vpkg/
v -prod .
```


## Copyright
(C) 2019 [Ned Palacios](https://github.com/nedpals)
