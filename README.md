# vpkg ![Latest version][githubBadge] ![Build status][workflowBadge]
vpkg is an alternative package manager written on [V](https://github.com/vlang/v) for V.

## Features
Bringing the best of dependency management on V.
- **Decentralized.** Download and use packages from other sources aside from VPM and the vpkg registry.
- **Easy to use.** Set-up, use, and master the commands of vpkg CLI within minutes.
- **Fast.** Runs perfectly on your potato PC up to the fastest supercomputers.
- **Interoperable.** Supports `v.mod`, and `.vpm.json` for reading package manifests and managing dependencies.
- **Light.** Weighs at less than 300kb. Perfect with devices running on tight storage or in low network conditions.
- **Reliable.** Uses a lockfile mechanism to ensure that all your dependencies work across all of your machines.

## Installation
### Pre-built binaries
Install vpkg by downloading the pre-built binaries available found below the release notes of the [latest release](https://github.com/vpkg-project/vpkg/releases).

### Building from Source
For those platforms which aren't included in the available pre-built binaries or would like to compile it by yourself, just clone this repository and build directly with the V compiler with the `-prod` flag.
```
git clone https://github.com/vpkg-project/vpkg.git
cd vpkg/
v -prod .
```

## Running your own registry
Use the provided [registry server template](https://github.com/vpkg-project/registry-template) to start running your own registry server. Just modify `registry.json` and use any HTTP or web library of your choice to get up and running.

## Commands
```
Usage: vpkg <COMMAND> [ARGS...] [options]

COMMANDS

get [packages]                             Fetch and installs packages from the registry or the git repo.
help                                       Show this help message.
info                                       Show project's package information.
init                                       Create a package manifest file into the current directory. Defaults to "vpkg".
install                                    Read the package manifest file and installs the necessary packages.
link                                       Symlink current module/package to ".vmodules" folder.
migrate manifest                           Migrate manifest file to a specified format.
release                                    Release a new version of the module.
remove [packages]                          Remove packages
test                                       Test the current lib/app.
update                                     Update the packages.
unlink                                     Remove the symlink of current module/package from ".vmodules" folder.
version                                    Show the version of this program.

OPTIONS

--files [file1,file2]                      Specifiy other locations of test files (For "test" command)
--force                                    Force download the packages.
--format [vpkg|vmod]                       Specifiy file format used to init manifest. (For "migrate" and "init" commands)
--global, -g                               Install the modules/packages into the ".vmodules" folder.
--inc [major|minor|patch]                  Increment the selected version of the module/package. (For "release" command)
--state [state_name]                       Indicate the state of the release (alpha, beta, fix) (For "release" command)
```

## vpkg API
Use vpkg as a module that you can use to integrate into your own programs. Create your own VSH scripts, automated installation, and more without needing a separate CLI program.

```v
// install.v
module main

import vpkg.api as vpkg // or import nedpals.vpkg.api as vpkg

fn main() {
    mut inst := vpkg.new('.')
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

## Roadmap
- ability to publish packages into VPM and the vpkg registry.
- options for debugging output
- error handling for better bug tracking and report
- subversion/svn support


## Copyright
(C) 2019 [Ned Palacios](https://github.com/nedpals)

[githubBadge]: https://img.shields.io/github/v/release/vpkg-project/vpkg?include_prereleases
[workflowBadge]: https://img.shields.io/github/workflow/status/vpkg-project/vpkg/CI
