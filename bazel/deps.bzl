load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")
load("@com_github_nelhage_rules_boost//:boost/boost.bzl", "boost_deps")
load("@rules_cuda//cuda:dependencies.bzl", "rules_cuda_dependencies")
load("@rules_fuzzing//fuzzing:repositories.bzl", "rules_fuzzing_dependencies")

def galaxy_dependencies():
    bazel_skylib_workspace()

    boost_deps()
    rules_fuzzing_dependencies()

    # rules_cc_dependencies()
    rules_cuda_dependencies(with_rules_cc = False)
