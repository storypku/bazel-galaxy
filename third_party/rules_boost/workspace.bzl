load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def repo():
    # latest as of Jan 19, 2022
    git_rev = "685557254da7ee57afc1204189b58253972e16be"
    http_archive(
        name = "com_github_nelhage_rules_boost",
        sha256 = "11e436c3888f6c9583ea2e0beabb12167186b5c1d191722d191ea13a46a60c7a",
        strip_prefix = "rules_boost-{}".format(git_rev),
        urls = [
            "https://github.com/nelhage/rules_boost/archive/{}.tar.gz".format(git_rev),
        ],
    )
