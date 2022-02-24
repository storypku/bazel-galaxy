load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# Hedron's Compile Commands Extractor for Bazel
# https://github.com/hedronvision/bazel-compile-commands-extractor

# NOTE(Jiaming): Can't work with Python < 3.7

def repo():
    git_rev = "1d21dc390e20ecb24d73e9dbb439e971e0d30337"
    http_archive(
        name = "hedron_compile_commands",
        sha256 = "9fda864ddae428ad0e03f7669ff4451554afac116e913cd2cd619ac0f40db8d9",
        strip_prefix = "bazel-compile-commands-extractor-{}".format(git_rev),
        urls = [
            "https://github.com/hedronvision/bazel-compile-commands-extractor/archive/{}.tar.gz".format(git_rev),
        ],
    )
