load("@rules_cc//cc:defs.bzl", "cc_binary")
load("//bazel/rules:cuda.bzl", "cuda_binary", "cuda_library")

package(default_visibility = ["//visibility:public"])

cuda_library(
    name = "kernel",
    srcs = ["kernel.cu"],
    hdrs = ["kernel.h"],
)

cc_binary(
    name = "hello",
    srcs = ["hello.cc"],
    deps = [":kernel"],
)

cuda_binary(
    name = "vector_add_sample",
    srcs = ["vector_add_sample.cu.cc"],
)
