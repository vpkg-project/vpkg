module main

struct Package {
    name string
    url string
}

struct InstalledPackage {
mut:
    name string    [skip]
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
mut:
    version string
    packages map[string]InstalledPackage
}