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

cc_library(
    name = "image_helper",
    srcs = ["image_helper.cc"],
    hdrs = ["image_helper.h"],
    deps = [
        ":cuda_helper",
    ],
)

cc_library(
    name = "cufft_helper",
    srcs = ["cufft_helper.cc"],
    hdrs = ["cufft_helper.h"],
    deps = [
        "@local_config_cuda//cuda:cufft",
    ],
)

cc_library(
    name = "cusparse_helper",
    srcs = ["cusparse_helper.cc"],
    hdrs = ["cusparse_helper.h"],
    deps = [
        "@local_config_cuda//cuda:cusparse",
    ],
)

cuda_library(
    name = "cusolver_helper",
    srcs = ["cusolver_helper.cc"],
    hdrs = ["cusolver_helper.h"],
    deps = [
        "@local_config_cuda//cuda:cusolver",
        "@local_config_cuda//cuda:cusparse",
    ],
)
