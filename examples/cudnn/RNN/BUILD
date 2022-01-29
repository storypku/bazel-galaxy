load("//bazel:rules_cuda.bzl", "cuda_binary", "cuda_library")

package(default_visibility = ["//visibility:public"])

cuda_library(
    name = "fp16_emu",
    srcs = ["fp16_emu.cpp"],
    hdrs = ["fp16_emu.h"],
)

cuda_binary(
    name = "RNN_example",
    srcs = ["RNN_example.cu"],
    deps = [
        ":fp16_emu",
        "@local_config_cuda//cuda:cudnn",
    ],
)
