load("//bazel/rules:cuda.bzl", "cuda_binary", "cuda_library")

package(default_visibility = ["//visibility:public"])

cuda_library(
    name = "batchCUBLAS",
    srcs = ["batchCUBLAS.cpp"],
    hdrs = ["batchCUBLAS.h"],
    deps = [
        "//examples/cuda/common:cuda_helper",
        "@local_config_cuda//cuda:cublas_headers",
        "@local_config_cuda//cuda:cublas",
    ],
)

cuda_binary(
    name = "batchCUBLAS_demo",
    srcs = ["batchCUBLAS_demo.cpp"],
    deps = [
        ":batchCUBLAS",
    ],
)
