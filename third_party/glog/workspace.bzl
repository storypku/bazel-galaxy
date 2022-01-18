load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def repo(with_gflags = 1):
    http_archive(
        name = "com_github_google_glog",
        strip_prefix = "glog-0.5.0",
        sha256 = "eede71f28371bf39aa69b45de23b329d37214016e2055269b3b5e7cfd40b59f5",
        build_file_content = """
licenses(['notice'])
load(':bazel/glog.bzl', 'glog_library')
glog_library(with_gflags={})
""".format(with_gflags),
        urls = ["https://github.com/google/glog/archive/v0.5.0.tar.gz"],
    )
