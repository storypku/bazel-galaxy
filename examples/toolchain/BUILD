load("@rules_cc//cc:defs.bzl", "cc_binary")
load(":compiler_flag.bzl", "compiler_flag")

package(default_visibility = ["//visibility:public"])

compiler_flag(name = "compiler")

config_setting(
    name = "llvm",
    flag_values = {
        ":compiler": "clang",
    },
    visibility = [
        ":__subpackages__",
    ],
)

cc_binary(
    name = "clang_vs_gcc",
    srcs = ["clang_vs_gcc.cc"],
    copts = select({
        ":llvm": ["-DGALAXY_COMPILER_CLANG"],
        "//conditions:default": [],
    }),
)
