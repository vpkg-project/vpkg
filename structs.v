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
    path string   [skip]
    version string
}

struct PkgInfo {
    name string
    author []string
    version string
    repo string
    packages []string
}

struct VpmPackage {
    id int
    name string
    url string
    nr_downloads int
}

struct Lockfile {
pub mut:
    version string
    packages []InstalledPackage
}