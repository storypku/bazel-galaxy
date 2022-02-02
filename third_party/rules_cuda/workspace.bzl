load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def clean_dep(dep):
    return str(Label(dep))

def repo():
    git_rev = "3bf5e37a6c091cb12d702896b1c6365d6758863e"
    http_archive(
        name = "rules_cuda",
        sha256 = "e2d6007e9d9065b9d4dc1b4332b7124c0db603944d892870859d34403e95f3c5",
        strip_prefix = "runtime-{}/third_party/rules_cuda".format(git_rev),
        urls = ["https://github.com/tensorflow/runtime/archive/{}.tar.gz".format(git_rev)],
        patch_args = ["-p3"],
        patches = [
            clean_dep("//third_party/rules_cuda:p01_sm_86_support.patch"),
            clean_dep("//third_party/rules_cuda:p02_cuda_path_workaround.patch"),
        ],
    )
