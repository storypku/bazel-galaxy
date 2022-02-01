load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def clean_dep(dep):
    return str(Label(dep))

def repo(with_gflags = 1):
    tag = "0.6.3"
    http_archive(
        name = "com_grail_bazel_toolchain",
        sha256 = "da607faed78c4cb5a5637ef74a36fdd2286f85ca5192222c4664efec2d529bb8",
        strip_prefix = "bazel-toolchain-{}".format(tag),
        canonical_id = tag,
        urls = [
            "https://github.com/grailbio/bazel-toolchain/archive/{}.tar.gz".format(tag),
        ],
        patch_args = ["-p1"],
        patches = [
            clean_dep("//third_party/bazel_toolchain:p01_cuda_support.patch"),
        ],
    )
