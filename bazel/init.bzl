load("@rules_cc//cc:repositories.bzl", "rules_cc_toolchains")
load("@rules_fuzzing//fuzzing:init.bzl", "rules_fuzzing_init")

def galaxy_init():
    rules_cc_toolchains()
    rules_fuzzing_init()
