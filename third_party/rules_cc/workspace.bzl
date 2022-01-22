load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def clean_dep(dep):
    return str(Label(dep))

def repo():
    if native.existing_rule("rules_cc"):
        fail("@rules_cc repository already exists. Unable to patch feature 'cuda'.")
    git_rev = "081771d4a0e9d7d3aa0eed2ef389fa4700dfb23e"
    http_archive(
        name = "rules_cc",
        strip_prefix = "rules_cc-{}".format(git_rev),
        sha256 = "ff7876d80cd3f6b8c7a064bd9aa42a78e02096544cca2b22a9cf390a4397a53e",
        urls = [
            "https://github.com/bazelbuild/rules_cc/archive/{}.tar.gz".format(git_rev),
        ],
        patches = [clean_dep("//third_party/rules_cc:p01_feature_cuda.patch")],
    )
