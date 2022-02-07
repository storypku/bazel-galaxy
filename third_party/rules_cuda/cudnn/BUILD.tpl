load("@rules_cc//cc:defs.bzl", "cc_library")

package(default_visibility = ["//visibility:public"])

cc_library(
    name = "cudnn",
    srcs = ["lib/%{cudnn_lib}"],
    hdrs = [":cudnn-include"],
    linkstatic = 1,
    deps = [
        "@local_config_cuda//cuda:cuda_headers",
    ],
)

%{copy_rules}
