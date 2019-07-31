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
    version string
    repo string
    packages []string
}