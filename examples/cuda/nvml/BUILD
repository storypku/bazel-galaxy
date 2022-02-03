load("@rules_cc//cc:defs.bzl", "cc_binary")

package(default_visibility = ["//visibility:public"])

cc_binary(
    name = "example",
    srcs = ["example.c"],
    deps = [
        "@local_config_cuda//nvml",
    ],
)

cc_binary(
    name = "supportedVgpus",
    srcs = ["supportedVgpus.c"],
    deps = [
        "@local_config_cuda//nvml",
    ],
)
