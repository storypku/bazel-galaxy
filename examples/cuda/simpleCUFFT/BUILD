load("//bazel/rules:cuda.bzl", "cuda_binary")

package(default_visibility = ["//visibility:public"])

cuda_binary(
    name = "simpleCUFFT",
    srcs = ["simpleCUFFT.cu"],
    deps = [
        "//examples/cuda/common:cuda_helper",
        "//examples/cuda/common:cufft_helper",
        "//examples/cuda/common:image_helper",
        "@local_config_cuda//cuda:cufft",
    ],
)
