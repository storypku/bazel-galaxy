load("@rules_cc//cc:defs.bzl", "cc_test")
load("//bazel:rules_cuda.bzl", "cuda_library")

package(default_visibility = ["//visibility:public"])

cuda_library(
    name = "rng",
    srcs = ["rng.cc"],
    hdrs = ["rng.h"],
    deps = [
        #        "//examples/cuda/common:cuda_helper",
        "@local_config_cuda//cuda:curand",
    ],
)

cc_test(
    name = "rng_test",
    srcs = ["rng_test.cc"],
    deps = [
        ":rng",
        "@com_google_googletest//:gtest_main",
    ],
)
