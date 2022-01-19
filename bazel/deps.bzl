load("@com_github_nelhage_rules_boost//:boost/boost.bzl", "boost_deps")
load("@rules_fuzzing//fuzzing:repositories.bzl", "rules_fuzzing_dependencies")

def galaxy_dependencies():
    boost_deps()
    rules_fuzzing_dependencies()
