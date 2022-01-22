load("@rules_cc//cc:defs.bzl", "cc_binary")
load("@rules_cuda//cuda:defs.bzl", "cuda_library", "requires_cuda_enabled")

package(default_visibility = ["//visibility:public"])

cuda_library(
    name = "kernel",
    srcs = ["kernel.cu"],
    hdrs = ["kernel.h"],
    target_compatible_with = requires_cuda_enabled(),
)

cc_binary(
    name = "hello",
    srcs = ["hello.cc"],
    deps = [":kernel"],
)
