module main

struct Registry {
    packages []Package
}

struct Package {
    name string
    url string
    method string
}

struct InstalledPackage {
pub mut:
    name string
    path string
    version string
}

struct PkgInfo {
    name string
    author []string
    version string
    repo string
    packages []string
}

struct Lockfile {
pub mut:
    version string
    packages []InstalledPackage
}