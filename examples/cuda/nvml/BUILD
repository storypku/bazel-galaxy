load("@rules_cc//cc:defs.bzl", "cc_binary")

package(default_visibility = ["//visibility:public"])

cc_binary(
    name = "example",
    srcs = ["example.cc"],
    deps = [
        "@local_config_cuda//nvml",
    ],
)

cc_binary(
    name = "supportedVgpus",
    srcs = ["supportedVgpus.cc"],
    deps = [
        "@local_config_cuda//nvml",
    ],
)
