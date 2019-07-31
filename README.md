# vpkg 
vpkg is a package manager written on [V](https://github.com/vlang/v) for V.

## The approach
vpkg's approach is to incorporate the ideas taken from centralized and decentralized package managers.
- Centralized, popular packages are being listed on to a single [`registry.json`](registry/registry.json) file.
- Uses a single, JSON file for storing package information as well as it's dependencies. (In this case, [`.vpkg.json`](.vpkg.json))
- Packages stored from the `registry.json` file can be obtained through a simple `vpkg get [package name]` while the rest uses regular Git URLs.

But there are some things that make's vpkg unique:
- Downloads and installs the modules to a single folder. (For now, it maybe in your project folder or your compiler's `vlib` folder).
- Instead of installing many modules per project, it shares the common modules to reduce project file size and download times.

### TODO
- Integration of the main Vlang package registry server.

## Development
1. Download and install [v-args](https://github.com/nedpals/v-args) and place it into the folder where your vpkg source code is located.
2. Run the registry server using `http-server` or similar tools.

## Copyright
(C) 2019 [Ned Palacios](https://github.com/nedpals)
