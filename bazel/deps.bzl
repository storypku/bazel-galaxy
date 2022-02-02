load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")
load("@com_github_nelhage_rules_boost//:boost/boost.bzl", "boost_deps")
load("@com_grail_bazel_toolchain//toolchain:rules.bzl", "llvm_toolchain")
load("@rules_cuda//cuda:dependencies.bzl", "rules_cuda_dependencies")
load("@rules_fuzzing//fuzzing:repositories.bzl", "rules_fuzzing_dependencies")

def galaxy_dependencies():
    bazel_skylib_workspace()

    boost_deps()
    rules_fuzzing_dependencies()

    # rules_cc_dependencies()
    rules_cuda_dependencies(with_rules_cc = False)

    # NOTE(storypku): llvm toolchain for bazel depends solely on rules_cc. However,
    # we already have our own rules_cc with feature cuda. Commented out code below.
    # load("@com_grail_bazel_toolchain//toolchain:deps.bzl", "bazel_toolchain_dependencies")
    # bazel_toolchain_dependencies()
    llvm_toolchain(
        name = "llvm_toolchain",
        llvm_version = "13.0.0",
        # absolute_paths = True,
    )
