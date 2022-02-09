# Copyright 2018 The Bazel Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

load("@local_config_llvm//:cc_toolchain_config.bzl", "cc_toolchain_config")
load("@local_cuda//:defs.bzl", "if_local_cuda")
load("@rules_cc//cc:defs.bzl", "cc_toolchain")

package(default_visibility = ["//visibility:public"])

filegroup(
    name = "empty",
)

# CC toolchain for cc-clang-%{arch}-linux.

toolchain(
    name = "cc-toolchain-%{arch}-linux",
    exec_compatible_with = [
        "@platforms//cpu:%{arch}",
        "@platforms//os:linux",
    ],
    target_compatible_with = [
        "@platforms//cpu:%{arch}",
        "@platforms//os:linux",
    ],
    toolchain = ":cc-clang-%{arch}-linux",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)

cc_toolchain(
    name = "cc-clang-%{arch}-linux",
    all_files = if_local_cuda("@local_cuda//:compiler_deps", ":empty"),
    ar_files = ":empty",
    as_files = ":empty",
    compiler_files = if_local_cuda("@local_cuda//:compiler_deps", ":empty"),
    dwp_files = ":empty",
    linker_files = ":empty",
    objcopy_files = ":empty",
    strip_files = ":empty",
    supports_param_files = 1,
    toolchain_config = ":local-clang-%{arch}-linux",
)

cc_toolchain_config(
    name = "local-clang-%{arch}-linux",
    additional_include_dirs = [],
    host_arch = "%{arch}",
    llvm_version = "%{llvm_version}",
    sysroot_path = "",
    target_arch = "%{arch}",
    toolchain_path_prefix = "%{llvm_dir}/",
    tools_path_prefix = "%{llvm_dir}/",
)
