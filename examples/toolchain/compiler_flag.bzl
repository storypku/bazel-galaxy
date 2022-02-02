"""Rule that allows select() to differentiate between compilers."""

load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")

def _compiler_flag_impl(ctx):
    toolchain = find_cpp_toolchain(ctx)
    return [config_common.FeatureFlagInfo(value = toolchain.compiler)]

compiler_flag = rule(
    implementation = _compiler_flag_impl,
    attrs = {
        "_cc_toolchain": attr.label(default = Label("@bazel_tools//tools/cpp:current_cc_toolchain")),
    },
    toolchains = ["@bazel_tools//tools/cpp:toolchain_type"],
    incompatible_use_toolchain_transition = True,
)
