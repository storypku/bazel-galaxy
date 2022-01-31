load("//bazel:rules_cuda.bzl", "cuda_binary")

package(default_visibility = ["//visibility:public"])

cuda_binary(
    name = "example",
    srcs = ["example.cc"],
    deps = [
        "@local_config_cuda//nccl",
    ],
)
