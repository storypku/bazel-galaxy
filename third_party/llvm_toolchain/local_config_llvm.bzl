load("//third_party:common.bzl", "err_out", "execute")

_LLVM_BINARIES = [
    "clang",
    "clang-cpp",
    "ld.lld",
    "llvm-ar",
    "llvm-as",
    "llvm-nm",
    "llvm-objcopy",
    "llvm-objdump",
    "llvm-profdata",
    "llvm-dwp",
    "llvm-ranlib",
    "llvm-readelf",
    "llvm-strip",
    "llvm-symbolizer",
]

_LLVM_VERSION_MINIMAL = "10.0.0"

def _label(filename):
    return Label("//third_party/llvm_toolchain:{}".format(filename))

def _check_llvm_binaries(repository_ctx, llvm_dir):
    for binary in _LLVM_BINARIES:
        binary_path = "{}/bin/{}".format(llvm_dir, binary)
        if not repository_ctx.path(binary_path).exists:
            fail("{} doesn't exist".format(binary_path))

def _retrieve_clang_version(repository_ctx, clang_binary):
    script_path = repository_ctx.path(Label("//third_party/llvm_toolchain:find_clang_version.py"))
    python_bin = repository_ctx.which("python3")
    result = execute(repository_ctx, [python_bin, script_path, clang_binary])
    if result.return_code:
        fail("Failed to run find_clang_version.py: {}".format(err_out(result)))
    llvm_version = result.stdout.strip()
    actual_version = [int(m) for m in llvm_version.split(".")]
    minimal_version = [int(m) for m in _LLVM_VERSION_MINIMAL.split(".")]
    if actual_version < minimal_version:
        fail("Minimal llvm version supported is {}, got: {}".format(_LLVM_VERSION_MINIMAL, llvm_version))
    return result.stdout.strip()

def _local_config_llvm_impl(repository_ctx):
    llvm_dir = repository_ctx.os.environ.get("LLVM_DIR", None)
    if not llvm_dir:
        fail("LLVM_DIR not set.")
    if llvm_dir.endswith("/"):
        llvm_dir = llvm_dir[:-1]

    _check_llvm_binaries(repository_ctx, llvm_dir)

    clang_binary = "{}/bin/clang".format(llvm_dir)
    llvm_version = _retrieve_clang_version(repository_ctx, clang_binary)

    repository_ctx.symlink(_label("cc_toolchain_config.bzl"), "cc_toolchain_config.bzl")

    arch = repository_ctx.execute(["uname", "-m"]).stdout.strip()
    repository_ctx.template(
        "toolchains.bzl",
        _label("toolchains.bzl.tpl"),
        {
            "%{arch}": arch,
        },
    )

    repository_ctx.template(
        "BUILD",
        _label("BUILD.tpl"),
        {
            "%{arch}": arch,
            "%{llvm_dir}": llvm_dir,
            "%{llvm_version}": llvm_version,
        },
    )

local_config_llvm = repository_rule(
    implementation = _local_config_llvm_impl,
    environ = ["LLVM_DIR"],
    local = True,
    # remotable = True,
)
