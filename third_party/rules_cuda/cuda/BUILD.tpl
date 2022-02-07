licenses(["restricted"])  # MPL2, portions GPL v3, LGPL v3, BSD-like

package(default_visibility = ["//visibility:public"])

cc_library(
    name = "cuda_headers",
    hdrs = [":cuda-include"],
    includes = ["include"],
)

cc_library(
    name = "cudart_static",
    srcs = ["lib/%{cudart_static_lib}"],
    linkopts = [
        "-ldl",
        "-lpthread",
        "-lrt",
    ],
    deps = [
        ":cuda_headers",
    ],
)

cc_library(
    name = "cuda_driver",
    srcs = ["lib/%{cuda_driver_lib}"],
    linkstatic = 1,
    deps = [
        ":cuda_headers",
    ],
)

cc_library(
    name = "cudart",
    srcs = ["lib/%{cudart_lib}"],
    linkstatic = 1,
    deps = [
        ":cuda_headers",
    ],
)

cc_library(
    name = "cublas",
    srcs = ["lib/%{cublas_lib}"],
    linkstatic = 1,
    deps = [
        ":cuda_headers",
    ],
)

cc_library(
    name = "cublasLt",
    srcs = ["lib/%{cublasLt_lib}"],
    linkstatic = 1,
    deps = [
        ":cuda_headers",
    ],
)

cc_library(
    name = "cufft",
    srcs = ["lib/%{cufft_lib}"],
    linkstatic = 1,
    deps = [
        ":cuda_headers",
    ],
)

cc_library(
    name = "cusolver",
    srcs = ["lib/%{cusolver_lib}"],
    linkopts = ["-lgomp"],
    linkstatic = 1,
    deps = [
        ":cuda_headers",
    ],
)

cc_library(
    name = "curand",
    srcs = ["lib/%{curand_lib}"],
    linkstatic = 1,
    deps = [
        ":cuda_headers",
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
    ],
)

cc_library(
    name = "cusparse",
    srcs = ["lib/%{cusparse_lib}"],
    linkopts = ["-lgomp"],
    linkstatic = 1,
    deps = [
        ":cuda_headers",
    ],
)

cc_library(
    name = "cupti",
    srcs = ["lib/%{cupti_lib}"],
    deps = [
        ":cuda_headers",
    ],
)

%{copy_rules}
