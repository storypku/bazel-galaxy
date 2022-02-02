# Copyright 2021 The Bazel Authors.
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

# NOTE(Jiaming): generated_symlink local_config_cc//:cc_toolchain_config.bzl
load(
    "@rules_cc//cc/private/toolchain:unix_cc_toolchain_config.bzl",
    unix_cc_toolchain_config = "cc_toolchain_config",
)

SUPPORTED_ARCHS = ["x86_64", "aarch64"]

# Macro for calling cc_toolchain_config from @rules_cc with setting the
# right paths and flags for the tools.
def cc_toolchain_config(
        name,
        host_arch,
        target_arch,
        toolchain_path_prefix,
        tools_path_prefix,
        sysroot_path,
        additional_include_dirs,
        llvm_version):
    # Check for compatibility.
    if host_arch not in SUPPORTED_ARCHS or target_arch not in SUPPORTED_ARCHS:
        fail("Either host arch {} or target arch {} is unsupported".format(host_arch, target_arch))

    # Only support recent LLVM releases.
    llvm_version_split = llvm_version.split(".") if llvm_version else None
    llvm_version_major = int(llvm_version_split[0]) if llvm_version_split else 0
    if llvm_version_major < 10:
        fail("LLVM version >= 10.0.0 expected, got: {}".format(llvm_version))

    target_os_arch_key = "linux-{}".format(target_arch)

    # A bunch of variables that get passed straight through to
    # `create_cc_toolchain_config_info`.
    # TODO: What do these values mean, and are they actually all correct?
    host_system_name = host_arch
    (
        toolchain_identifier,
        target_system_name,
        target_cpu,
        target_libc,
        compiler,
        abi_version,
        abi_libc_version,
    ) = {
        "linux-aarch64": (
            "clang-aarch64-linux",
            "aarch64-unknown-linux-gnu",
            "aarch64",
            "glibc_unknown",
            "clang",
            "clang",
            "glibc_unknown",
        ),
        "linux-x86_64": (
            "clang-x86_64-linux",
            "x86_64-unknown-linux-gnu",
            "k8",
            "glibc_unknown",
            "clang",
            "clang",
            "glibc_unknown",
        ),
    }[target_os_arch_key]

    # Unfiltered compiler flags:
    unfiltered_compile_flags = [
        # Do not resolve our symlinked resource prefixes to real paths.
        "-no-canonical-prefixes",
        # Reproducibility
        "-Wno-builtin-macro-redefined",
        "-D__DATE__=\"redacted\"",
        "-D__TIMESTAMP__=\"redacted\"",
        "-D__TIME__=\"redacted\"",
        # "-fdebug-prefix-map={}=__bazel_toolchain_llvm_repo__/".format(toolchain_path_prefix),
    ]

    is_xcompile = not (host_arch == target_arch)

    # Default compiler flags:
    compile_flags = [
        "--target=" + target_system_name,
        # Security
        "-U_FORTIFY_SOURCE",  # https://github.com/google/sanitizers/issues/247
        "-fstack-protector",
        "-fno-omit-frame-pointer",
        # Diagnostics
        "-fcolor-diagnostics",
        "-Wall",
        "-Wthread-safety",
        "-Wself-assign",
    ]

    dbg_compile_flags = ["-g", "-fstandalone-debug"]

    opt_compile_flags = [
        "-g0",
        "-O2",
        "-D_FORTIFY_SOURCE=1",
        "-DNDEBUG",
        "-ffunction-sections",
        "-fdata-sections",
    ]

    link_flags = [
        "--target=" + target_system_name,
        "-lm",
        "-no-canonical-prefixes",
    ]
    link_libs = []

    # Linker flags:
    use_lld = True
    link_flags.extend([
        "-fuse-ld=lld",
        "-Wl,--build-id=md5",
        "-Wl,--hash-style=gnu",
        "-Wl,-z,relro,-z,now",
    ])

    # Flags related to C++ standard.
    # The linker has no way of knowing if there are C++ objects; so we
    # always link C++ libraries.
    if not is_xcompile:
        cxx_flags = [
            "-std=c++17",
            "-stdlib=libc++",
        ]

        # For single-platform builds, we can statically link the bundled
        # libraries.
        link_flags.extend([
            "-L{}lib".format(toolchain_path_prefix),
            "-l:libc++.a",
            "-l:libc++abi.a",
            "-l:libunwind.a",
            # Compiler runtime features.
            "-rtlib=compiler-rt",
        ])
        link_libs.extend([
            # To support libunwind.
            "-lpthread",
            "-ldl",
        ])
        # link_flags.extend([
        #         "-lc++",
        #        "-lc++abi",
        #    ])

    else:
        cxx_flags = [
            "-std=c++17",
            "-stdlib=libstdc++",
        ]

        # For xcompile, we expect to pick up these libraries from the sysroot.
        link_flags.extend([
            "-l:libstdc++.a",
        ])

    opt_link_flags = ["-Wl,--gc-sections"]

    # Coverage flags:
    coverage_compile_flags = ["-fprofile-instr-generate", "-fcoverage-mapping"]
    coverage_link_flags = ["-fprofile-instr-generate"]

    # C++ built-in include directories:
    cxx_builtin_include_directories = [
        toolchain_path_prefix + "include/c++/v1",
        toolchain_path_prefix + "lib/clang/{}/include".format(llvm_version),
        toolchain_path_prefix + "lib64/clang/{}/include".format(llvm_version),
    ]

    sysroot_prefix = ""
    if sysroot_path:
        sysroot_prefix = "%sysroot%"

    cxx_builtin_include_directories.extend([
        sysroot_prefix + "/include",
        sysroot_prefix + "/usr/include",
        sysroot_prefix + "/usr/local/include",
    ])

    cxx_builtin_include_directories.extend(additional_include_dirs)

    ## NOTE: make variables are missing here; unix_cc_toolchain_config doesn't
    ## pass these to `create_cc_toolchain_config_info`.

    # The tool names come from [here](https://github.com/bazelbuild/bazel/blob/c7e58e6ce0a78fdaff2d716b4864a5ace8917626/src/main/java/com/google/devtools/build/lib/rules/cpp/CppConfiguration.java#L76-L90):
    tool_paths = {
        "ar": tools_path_prefix + "bin/llvm-ar",
        "cpp": tools_path_prefix + "bin/clang-cpp",
        "dwp": tools_path_prefix + "bin/llvm-dwp",
        "gcc": tools_path_prefix + "bin/clang",
        "gcov": tools_path_prefix + "bin/llvm-profdata",
        "ld": tools_path_prefix + "bin/ld.lld" if use_lld else "/usr/bin/ld",
        "llvm-cov": tools_path_prefix + "bin/llvm-cov",
        "llvm-profdata": tools_path_prefix + "bin/llvm-profdata",
        "nm": tools_path_prefix + "bin/llvm-nm",
        "objcopy": tools_path_prefix + "bin/llvm-objcopy",
        "objdump": tools_path_prefix + "bin/llvm-objdump",
        "strip": tools_path_prefix + "bin/llvm-strip",
    }

    # Start-end group linker support:
    # This was added to `lld` in this patch: http://reviews.llvm.org/D18814
    #
    # The oldest version of LLVM that we support is 6.0.0 which was released
    # after the above patch was merged, so we just set this to `True` when
    # `lld` is being used as the linker.
    supports_start_end_lib = use_lld

    # Source: https://github.com/bazelbuild/rules_cc/blob/main/cc/private/toolchain/unix_cc_toolchain_config.bzl
    unix_cc_toolchain_config(
        name = name,
        cpu = target_cpu,
        compiler = compiler,
        toolchain_identifier = toolchain_identifier,
        host_system_name = host_system_name,
        target_system_name = target_system_name,
        target_libc = target_libc,
        abi_version = abi_version,
        abi_libc_version = abi_libc_version,
        cxx_builtin_include_directories = cxx_builtin_include_directories,
        tool_paths = tool_paths,
        compile_flags = compile_flags,
        dbg_compile_flags = dbg_compile_flags,
        opt_compile_flags = opt_compile_flags,
        cxx_flags = cxx_flags,
        link_flags = link_flags,
        link_libs = link_libs,
        opt_link_flags = opt_link_flags,
        unfiltered_compile_flags = unfiltered_compile_flags,
        coverage_compile_flags = coverage_compile_flags,
        coverage_link_flags = coverage_link_flags,
        supports_start_end_lib = supports_start_end_lib,
    )
