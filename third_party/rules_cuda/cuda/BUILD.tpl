licenses(["restricted"])  # MPL2, portions GPL v3, LGPL v3, BSD-like

package(default_visibility = ["//visibility:public"])

cc_library(
    name = "cudart_static",
    srcs = ["cuda/lib/%{cudart_static_lib}"],
    linkopts = [
        "-ldl",
        "-lpthread",
        "-lrt",
    ],
    deps = [
        "@local_cuda//:cuda_headers",
    ],
)

cc_library(
    name = "cuda_driver",
    srcs = ["cuda/lib/%{cuda_driver_lib}"],
    deps = [
        "@local_cuda//:cuda_headers",
    ],
)

cc_library(
    name = "cudart",
    srcs = ["cuda/lib/%{cudart_lib}"],
    linkstatic = 1,
    deps = [
        "@local_cuda//:cuda_headers",
    ],
)

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

cc_library(
    name = "cufft",
    srcs = ["cuda/lib/%{cufft_lib}"],
    linkstatic = 1,
    deps = [
        "@local_cuda//:cuda_headers",
    ],
)

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

cc_library(
    name = "cupti",
    srcs = ["cuda/lib/%{cupti_lib}"],
    deps = [
        "@local_cuda//:cuda_headers",
    ],
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

%{copy_rules}
