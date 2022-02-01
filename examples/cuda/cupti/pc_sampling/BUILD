load("//bazel:rules_cuda.bzl", "cuda_binary")

package(default_visibility = ["//visibility:public"])

cuda_binary(
    name = "pc_sampling",
    srcs = ["pc_sampling.cu"],
    deps = [
        "@local_config_cuda//cuda:cuda_driver",
        "@local_config_cuda//cuda:cupti",
    ],
)
