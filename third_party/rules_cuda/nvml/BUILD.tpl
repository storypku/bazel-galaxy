load("@rules_cc//cc:defs.bzl", "cc_library")

package(default_visibility = ["//visibility:public"])

cc_library(
    name = "nvml",
    srcs = ["lib/%{nvml_lib}"],
    hdrs = [":nvml-include"],
    target_compatible_with = [
        "@platforms//cpu:x86_64",
    ],
)

%{copy_rules}
