load("@rules_cc//cc:defs.bzl", "cc_library", "cc_test")
load("//bazel/rules:cuda.bzl", "cuda_library")

package(default_visibility = ["//visibility:public"])

cc_library(
    name = "string_helper",
    hdrs = ["string_helper.h"],
)

cuda_library(
    name = "cuda_helper",
    srcs = ["cuda_helper.cc"],
    hdrs = ["cuda_helper.h"],
    deps = [
        ":string_helper",
    ],
)

cc_test(
    name = "cuda_helper_test",
    size = "small",
    srcs = ["cuda_helper_test.cc"],
    deps = [
        ":cuda_helper",
        "@com_google_googletest//:gtest_main",
    ],
)
