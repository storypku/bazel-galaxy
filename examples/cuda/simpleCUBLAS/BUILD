load("//bazel/rules:cuda.bzl", "cuda_binary", "cuda_library")

package(default_visibility = ["//visibility:public"])

cuda_binary(
    name = "simpleCUBLAS",
    srcs = ["simpleCUBLAS.cpp"],
    deps = [
        "//examples/cuda/common:cuda_helper",
        "@local_config_cuda//cuda:cublas_headers",
        "@local_config_cuda//cuda:cublas",
    ],
)
