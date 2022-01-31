load("@rules_cc//cc:defs.bzl", "cc_library")

filegroup(
    name = "LICENSE",
    visibility = ["//visibility:public"],
)

cc_library(
    name = "nccl",
    srcs = ["lib/libnccl.so.%{nccl_version}"],
    hdrs = ["include/nccl.h"],
    visibility = ["//visibility:public"],
    deps = [
        "@local_cuda//:cuda_headers",
    ],
)

genrule(
    name = "nccl-files",
    outs = [
        "lib/libnccl.so.%{nccl_version}",
        "include/nccl.h",
    ],
    cmd = """
cp "%{nccl_header_dir}/nccl.h" "$(@D)/include/nccl.h" &&
cp "%{nccl_library_dir}/libnccl.so.%{nccl_version}" \
  "$(@D)/lib/libnccl.so.%{nccl_version}"
""",
)
