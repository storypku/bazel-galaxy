load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def repo():
    version = "0.23.0"
    http_archive(
        name = "io_bazel_rules_docker",
        sha256 = "85ffff62a4c22a74dbd98d05da6cf40f497344b3dbf1e1ab0a37ab2a1a6ca014",
        strip_prefix = "rules_docker-{}".format(version),
        urls = [
            "https://github.com/bazelbuild/rules_docker/releases/download/v{0}/rules_docker-v{0}.tar.gz".format(version),
        ],
    )
