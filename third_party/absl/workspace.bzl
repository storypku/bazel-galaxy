load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def clean_dep(dep):
    return str(Label(dep))

def repo():
    version = "20211102.0"
    http_archive(
        name = "com_google_absl",
        sha256 = "dcf71b9cba8dc0ca9940c4b316a0c796be8fab42b070bb6b7cab62b48f0e66c4",
        urls = [
            "https://github.com/abseil/abseil-cpp/archive/refs/tags/{}.tar.gz".format(version),
        ],
        strip_prefix = "abseil-cpp-{}".format(version),
    )
