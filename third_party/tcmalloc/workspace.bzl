load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def repo():
    git_rev = "c9da0eab4728e145803692e876d9277da7fd2a6a"
    http_archive(
        name = "com_google_tcmalloc",
        urls = [
            "https://github.com/google/tcmalloc/archive/{}.tar.gz".format(git_rev),
        ],
        strip_prefix = "tcmalloc-{}".format(git_rev),
    )
