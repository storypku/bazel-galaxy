load("@rules_cc//cc:defs.bzl", "cc_library")

def cuda_header_library(
        name,
        hdrs,
        include_prefix = None,
        strip_include_prefix = None,
        deps = [],
        **kwargs):
    """Generates a cc_library containing both virtual and system include paths.

    Generates both a header-only target with virtual includes plus the full
    target without virtual includes. This works around the fact that bazel can't
    mix 'includes' and 'include_prefix' in the same target."""
    cc_library(
        name = name + "_virtual",
        hdrs = hdrs,
        include_prefix = include_prefix,
        strip_include_prefix = strip_include_prefix,
        deps = deps,
        visibility = ["//visibility:private"],
    )
    cc_library(
        name = name,
        textual_hdrs = hdrs,
        deps = deps + [":%s_virtual" % name],
        **kwargs
    )
