load("@rules_cc//cc:defs.bzl", "cc_binary")

package(default_visibility = ["//visibility:public"])

cc_binary(
    name = "simpleCUBLAS",
    srcs = ["simpleCUBLAS.cpp"],
    deps = [
        "//examples/cuda/common:cuda_helper",
        "@local_config_cuda//cuda:cublas",
    ],
)
