load("@rules_cc//cc:defs.bzl", "cc_library")
load("//bazel:rules_cuda.bzl", "cuda_binary")

package(default_visibility = ["//visibility:public"])

cc_library(
    name = "mmio",
    srcs = ["mmio.c"],
    hdrs = ["mmio.h"],
)

cc_library(
    name = "mmio_wrapper",
    hdrs = ["mmio_wrapper.h"],
    deps = [
        ":mmio",
    ],
)

cuda_binary(
    name = "cuSolverRf",
    srcs = ["cuSolverRf.cpp"],
    data = [
        ":data",
    ],
    deps = [
        ":mmio_wrapper",
        "//examples/cuda/common:cuda_helper",
        "//examples/cuda/common:cusolver_helper",
        "//examples/cuda/common:cusparse_helper",
        "//examples/cuda/common:string_helper",
        "@local_config_cuda//cuda:cusolver",
    ],
)

filegroup(
    name = "data",
    srcs = glob(["data/*.mtx"]),
)
