module main

struct Package {
    name string
    url string
}

struct DownloadedPackage {
    name string
    downloaded_path string
}

struct PkgInfo {
    name string
    version string
    repo string
    packages []string
}