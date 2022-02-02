load("@local_config_llvm//:toolchains.bzl", "llvm_register_toolchains")
load("@rules_cc//cc:repositories.bzl", "rules_cc_toolchains")
load("@rules_fuzzing//fuzzing:init.bzl", "rules_fuzzing_init")
load("//third_party/rules_cuda:local_config_cuda.bzl", "local_config_cuda")

def galaxy_init():
    llvm_register_toolchains()
    rules_cc_toolchains()

    rules_fuzzing_init()
    local_config_cuda(name = "local_config_cuda")
