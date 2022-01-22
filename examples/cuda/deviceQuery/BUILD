load("//bazel/rules:cuda.bzl", "cuda_binary")

package(default_visibility = ["//visibility:public"])

cuda_binary(
    name = "deviceQuery",
    srcs = ["deviceQuery.cpp"],
    deps = [
        "//examples/cuda/common:cuda_helper",
    ],
)
