load(":build_defs.bzl", "cuda_header_library")
load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

licenses(["restricted"])  # MPL2, portions GPL v3, LGPL v3, BSD-like

package(default_visibility = ["//visibility:public"])

# Provides CUDA headers for '#include "third_party/gpus/cuda/include/cuda.h"'
# All clients including TensorFlow should use these directives.
cuda_header_library(
    name = "cuda_headers",
    hdrs = [
        ":cuda-include",
    ],
    include_prefix = "third_party/gpus",
    includes = [
        "cuda/include",
    ],
)

cc_library(
    name = "cudart_static",
    srcs = ["cuda/lib/%{cudart_static_lib}"],
    linkopts = [
        "-ldl",
        "-lpthread",
        "-lrt",
    ],
)

cc_library(
    name = "cuda_driver",
    srcs = ["cuda/lib/%{cuda_driver_lib}"],
)

cc_library(
    name = "cudart",
    srcs = ["cuda/lib/%{cudart_lib}"],
    data = ["cuda/lib/%{cudart_lib}"],
    linkstatic = 1,
)

# Done
cc_library(
    name = "cublas",
    srcs = ["cuda/lib/%{cublas_lib}"],
    linkstatic = 1,
    deps = [
        "@local_cuda//:cuda_headers",
    ],
)

cc_library(
    name = "cublasLt",
    srcs = ["cuda/lib/%{cublasLt_lib}"],
    linkstatic = 1,
    deps = [
        "@local_cuda//:cuda_headers",
    ],
)

# Done
cc_library(
    name = "cufft",
    srcs = ["cuda/lib/%{cufft_lib}"],
    linkstatic = 1,
    deps = [
        "@local_cuda//:cuda_headers",
    ],
)

# Done
cc_library(
    name = "cusolver",
    srcs = ["cuda/lib/%{cusolver_lib}"],
    linkopts = ["-lgomp"],
    linkstatic = 1,
    deps = [
        "@local_cuda//:cuda_headers",
    ],
)

cc_library(
    name = "cudnn",
    srcs = ["cuda/lib/%{cudnn_lib}"],
    data = ["cuda/lib/%{cudnn_lib}"],
    linkstatic = 1,
)

cc_library(
    name = "cudnn_header",
    hdrs = [":cudnn-include"],
    include_prefix = "third_party/gpus/cudnn",
    strip_include_prefix = "cudnn/include",
    deps = [
        "@local_cuda//:cuda_headers",
    ],
)

# Done
cc_library(
    name = "curand",
    srcs = ["cuda/lib/%{curand_lib}"],
    linkstatic = 1,
    deps = [
        "@local_cuda//:cuda_headers",
    ],
)

cc_library(
    name = "cuda",
    deps = [
        ":cublas",
        ":cublasLt",
        ":cudart",
        ":cufft",
        ":curand",
        "@local_cuda//:cuda_headers",
    ],
)

cuda_header_library(
    name = "cupti_headers",
    hdrs = [":cuda-extras"],
    include_prefix = "third_party/gpus",
    includes = ["cuda/extras/CUPTI/include/"],
    deps = [":cuda_headers"],
)

cc_library(
    name = "cupti_dsos",
    data = ["cuda/lib/%{cupti_lib}"],
)

cc_library(
    name = "cusparse",
    srcs = ["cuda/lib/%{cusparse_lib}"],
    linkopts = ["-lgomp"],
    linkstatic = 1,
    deps = [
        "@local_cuda//:cuda_headers",
    ],
)

cc_library(
    name = "libdevice_root",
    data = [":cuda-nvvm"],
)

bzl_library(
    name = "build_defs_bzl",
    srcs = ["build_defs.bzl"],
    deps = [
        "@bazel_skylib//lib:selects",
    ],
)

%{copy_rules}
