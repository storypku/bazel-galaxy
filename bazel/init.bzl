load("@rules_cc//cc:repositories.bzl", "rules_cc_toolchains")
load("@rules_fuzzing//fuzzing:init.bzl", "rules_fuzzing_init")
load("//third_party/gpus:cuda_configure.bzl", "cuda_configure")
load("//third_party/rules_cuda:local_config_cuda.bzl", "local_config_cuda")

def galaxy_init():
    rules_cc_toolchains()
    rules_fuzzing_init()
    local_config_cuda(name = "local_config_cuda")
    cuda_configure(name = "local_config_cuda2")
