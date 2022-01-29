load("@rules_cc//cc:defs.bzl", "cc_library")

package(default_visibility = ["//visibility:public"])

cc_library(
    name = "cudnn",
    srcs = ["cudnn/lib/%{cudnn_lib}"],
    hdrs = [":cudnn-include"],
    linkstatic = 1,
    deps = [
        "@local_cuda//:cuda_headers",
    ],
)

%{copy_rules}
