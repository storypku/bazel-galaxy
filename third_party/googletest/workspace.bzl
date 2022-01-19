"""Loads the googletest library"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def repo():
    version = "1.11.0"
    http_archive(
        name = "com_google_googletest",
        sha256 = "b4870bf121ff7795ba20d20bcdd8627b8e088f2d1dab299a031c1034eddc93d5",
        strip_prefix = "googletest-release-{}".format(version),
        urls = [
            "https://github.com/google/googletest/archive/release-{}.tar.gz".format(version),
        ],
    )
