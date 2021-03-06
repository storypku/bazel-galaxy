load("@bazel_skylib//lib:paths.bzl", "paths")
load("//third_party:common.bzl", "err_out", "execute", "read_dir")

def auto_configure_fail(msg):
    """Output failure message when cuda configuration fails."""
    red = "\033[0;31m"
    no_color = "\033[0m"
    fail("\n{}Cuda Configuration Error:{} {}\n".format(red, no_color, msg))

def lib_name(base_name, version = None, static = False):
    """Constructs the name of a library on Linux.

      Args:
        base_name: The name of the library, such as "cudart"
        version: The version of the library.
        static: True the library is static or False if it is a shared object.

      Returns:
        The name of the library on linux
      """
    if static:
        return "lib{}.a".format(base_name)
    else:
        version = "." + version if version else ""
        return "lib{}.so{}".format(base_name, version)

def _check_cuda_lib_params(lib, basedir, version, static = False):
    lib_path = "{}/{}".format(basedir, lib_name(lib, version, static))
    return (lib_path, version and not static)

def _check_cuda_family_libs(repository_ctx, script_path, libs):
    # Verify that the libs actually exist at their locations.
    python_bin = repository_ctx.which("python3")
    contents = repository_ctx.read(script_path).splitlines()

    cmd = "from os import linesep;"
    cmd += "f = open('script.py', 'w');"
    for line in contents:
        cmd += "f.write('%s' + linesep);" % line
    cmd += "f.close();"
    cmd += "from os import system;"
    args = " ".join(["\"" + path + "\" " + str(check) for path, check in libs])
    cmd += "system('%s script.py %s');" % (python_bin, args)

    all_paths = [path for path, _ in libs]
    checked_paths = execute(repository_ctx, [python_bin, "-c", cmd]).stdout.splitlines()

    # Filter out empty lines from splitting on '\r\n' on Windows
    checked_paths = [path for path in checked_paths if len(path) > 0]
    if all_paths != checked_paths:
        auto_configure_fail("Error with installed CUDA libs. Expected '%s'. Actual '%s'." % (all_paths, checked_paths))

def _find_cuda_family_libs_impl(repository_ctx, params):
    check_script = repository_ctx.path(Label("//third_party/rules_cuda:check_cuda_libs.py"))
    _check_cuda_family_libs(repository_ctx, check_script, params.values())
    paths = {filename: v[0] for (filename, v) in params.items()}
    return paths

def _find_cuda_libs(repository_ctx, cuda_config):
    """Returns the CUDA and cuDNN libraries on the system.

      Also, verifies that the script actually exist.

      Args:
        repository_ctx: The repository context.
        cuda_config: The CUDA config as returned by _get_cuda_family_config

      Returns:
        Map of library names to structs of filename and path.
      """
    stub_dir = "/stubs"

    check_cuda_libs_params = {
        "cublas": _check_cuda_lib_params(
            "cublas",
            cuda_config.config["cublas_library_dir"],
            cuda_config.cublas_version,
            static = False,
        ),
        "cublasLt": _check_cuda_lib_params(
            "cublasLt",
            cuda_config.config["cublas_library_dir"],
            cuda_config.cublas_version,
            static = False,
        ),
        "cuda": _check_cuda_lib_params(
            "cuda",
            cuda_config.config["cuda_library_dir"] + stub_dir,
            version = None,
            static = False,
        ),
        "cudart": _check_cuda_lib_params(
            "cudart",
            cuda_config.config["cuda_library_dir"],
            cuda_config.cudart_version,
            static = False,
        ),
        "cudart_static": _check_cuda_lib_params(
            "cudart_static",
            cuda_config.config["cuda_library_dir"],
            cuda_config.cudart_version,
            static = True,
        ),
        "cufft": _check_cuda_lib_params(
            "cufft",
            cuda_config.config["cufft_library_dir"],
            cuda_config.cufft_version,
            static = False,
        ),
        "cupti": _check_cuda_lib_params(
            "cupti",
            cuda_config.config["cupti_library_dir"],
            cuda_config.cuda_version,
            static = False,
        ),
        "curand": _check_cuda_lib_params(
            "curand",
            cuda_config.config["curand_library_dir"],
            cuda_config.curand_version,
            static = False,
        ),
        "cusolver": _check_cuda_lib_params(
            "cusolver",
            cuda_config.config["cusolver_library_dir"],
            cuda_config.cusolver_version,
            static = False,
        ),
        "cusparse": _check_cuda_lib_params(
            "cusparse",
            cuda_config.config["cusparse_library_dir"],
            cuda_config.cusparse_version,
            static = False,
        ),
    }

    return _find_cuda_family_libs_impl(repository_ctx, check_cuda_libs_params)

def _find_cudnn_libs(repository_ctx, cuda_family_config):
    cudnn_params = {
        "cudnn": _check_cuda_lib_params(
            "cudnn",
            cuda_family_config.config["cudnn_library_dir"],
            cuda_family_config.cudnn_version,
            static = False,
        ),
    }

    return _find_cuda_family_libs_impl(repository_ctx, cudnn_params)

def _find_nvml_libs(repository_ctx, cuda_family_config):
    nvml_params = {
        "nvml": _check_cuda_lib_params(
            "nvidia-ml",
            cuda_family_config.config["nvml_library_dir"],
            "1",
            static = False,
        ),
    }
    return _find_cuda_family_libs_impl(repository_ctx, nvml_params)

# TODO(csigg): Only call once instead of from here, tensorrt_configure.bzl,
# and nccl_configure.bzl.
def find_cuda_family_config(repository_ctx, script_path, cuda_libraries):
    """Returns CUDA config dictionary from running find_cuda_config.py"""
    python_bin = repository_ctx.which("python3")
    exec_result = execute(repository_ctx, [python_bin, script_path] + cuda_libraries)
    if exec_result.return_code:
        errmsg = err_out(exec_result)
        auto_configure_fail("Failed to run find_cuda_config.py: {}".format(errmsg))

    # Parse the dict from stdout.
    return dict([tuple(x.split(": ")) for x in exec_result.stdout.splitlines()])

def _get_cuda_family_config(repository_ctx, find_cuda_config_script):
    """Detects and returns information about the CUDA installation on the system.

      Args:
        repository_ctx: The repository context.

      Returns:
        A struct containing the following fields:
          cuda_toolkit_path: The CUDA toolkit installation directory.
          cuda_version: The version of CUDA on the system.
          cudart_version: The CUDA runtime version on the system.
          cudnn_version: The version of cuDNN on the system.
          nccl_version: The version of NCCL on the system.
      """
    config = find_cuda_family_config(repository_ctx, find_cuda_config_script, ["cuda", "cudnn", "nccl"])
    toolkit_path = config["cuda_toolkit_path"]
    cuda_version = config["cuda_version"].split(".")
    cuda_major = cuda_version[0]
    cuda_minor = cuda_version[1]

    cuda_version = "{}.{}".format(cuda_major, cuda_minor)
    cudnn_version = config.get("cudnn_version", None)
    nccl_version = config.get("nccl_version", None)

    if int(cuda_major) >= 11:
        # The libcudart soname in CUDA 11.x is versioned as 11.0 for backward compatability.
        if int(cuda_major) == 11:
            cudart_version = "11.0"
        else:
            cudart_version = cuda_major
        cublas_version = config["cublas_version"].split(".")[0]
        cusolver_version = config["cusolver_version"].split(".")[0]
        curand_version = config["curand_version"].split(".")[0]
        cufft_version = config["cufft_version"].split(".")[0]
        cusparse_version = config["cusparse_version"].split(".")[0]
    elif (int(cuda_major), int(cuda_minor)) >= (10, 1):
        # cuda_lib_version is for libraries like cuBLAS, cuFFT, cuSOLVER, etc.
        # It changed from 'x.y' to just 'x' in CUDA 10.1.
        cuda_lib_version = cuda_major
        cudart_version = cuda_version
        cublas_version = cuda_lib_version
        cusolver_version = cuda_lib_version
        curand_version = cuda_lib_version
        cufft_version = cuda_lib_version
        cusparse_version = cuda_lib_version
    else:
        cudart_version = cuda_version
        cublas_version = cuda_version
        cusolver_version = cuda_version
        curand_version = cuda_version
        cufft_version = cuda_version
        cusparse_version = cuda_version

    return struct(
        cuda_toolkit_path = toolkit_path,
        cuda_version = cuda_version,
        cuda_version_major = cuda_major,
        cudart_version = cudart_version,
        cublas_version = cublas_version,
        cusolver_version = cusolver_version,
        curand_version = curand_version,
        cufft_version = cufft_version,
        cusparse_version = cusparse_version,
        cudnn_version = cudnn_version,
        nccl_version = nccl_version,
        config = config,
    )

def make_copy_files_rule(repository_ctx, name, srcs, outs):
    """Returns a rule to copy a set of files."""

    # Copy files.
    cmds = ['cp -f "{}" "$(location {})"'.format(src, out) for (src, out) in zip(srcs, outs)]
    outs = ['        "{}",'.format(out) for out in outs]
    return """genrule(
    name = "{}",
    outs = [
{}
    ],
    cmd = \"""{} \""",
)""".format(name, "\n".join(outs), " && \\\n".join(cmds))

def make_copy_dir_rule(repository_ctx, name, src_dir, out_dir, exceptions = None):
    """Returns a rule to recursively copy a directory.
    If exceptions is not None, it must be a list of files or directories in
    'src_dir'; these will be excluded from copying.
    """
    src_dir = paths.normalize(src_dir)
    out_dir = paths.normalize(out_dir)
    outs = read_dir(repository_ctx, src_dir)
    post_cmd = ""
    if exceptions != None:
        outs = [x for x in outs if not any([
            x.startswith(src_dir + "/" + y)
            for y in exceptions
        ])]
    outs = [('        "%s",' % out.replace(src_dir, out_dir)) for out in outs]

    # '@D' already contains the relative path for a single file, see
    # http://docs.bazel.build/versions/master/be/make-variables.html#predefined_genrule_variables
    out_dir = "$(@D)/%s" % out_dir if len(outs) > 1 else "$(@D)"
    if exceptions != None:
        for x in exceptions:
            post_cmd += " ; rm -fR " + out_dir + "/" + x
    return """genrule(
    name = "{}",
    outs = [
{}
    ],
    cmd = \"""cp -rLf "{}/." "{}/" {}\""",
)""".format(name, "\n".join(outs), src_dir, out_dir, post_cmd)

def _tpl_path(repository_ctx, filename):
    return repository_ctx.path(Label("//third_party/rules_cuda/{}.tpl".format(filename)))

def _render_nvml_template(repository_ctx, nvml_config):
    if "nvml_driver_version" not in nvml_config.config:
        print("NVML not found. Creating dummy NVML rule")
        nvml_build_dummy = Label("//third_party/rules_cuda/nvml:BUILD.dummy")
        repository_ctx.symlink(nvml_build_dummy, "nvml/BUILD")
        return

    nvml_headers = ["nvml.h"]
    nvml_include_dir = nvml_config.config["nvml_include_dir"]

    nvml_srcs = ["{}/{}".format(nvml_include_dir, header) for header in nvml_headers]
    nvml_outs = ["include/{}".format(header) for header in nvml_headers]

    copy_rules = [
        make_copy_files_rule(
            repository_ctx,
            name = "nvml-include",
            srcs = nvml_srcs,
            outs = nvml_outs,
        ),
    ]

    nvml_libs = _find_nvml_libs(repository_ctx, nvml_config)
    nvml_lib_srcs = []
    nvml_lib_outs = []
    for path in nvml_libs.values():
        nvml_lib_srcs.append(path)
        nvml_lib_outs.append("lib/" + paths.basename(path))

    copy_rules.append(make_copy_files_rule(
        repository_ctx,
        name = "nvml-lib",
        srcs = nvml_lib_srcs,
        outs = nvml_lib_outs,
    ))

    repository_ctx.template(
        "nvml/BUILD",
        _tpl_path(repository_ctx, "nvml:BUILD"),
        {
            "%{copy_rules}": "\n\n".join(copy_rules),
            "%{nvml_lib}": paths.basename(nvml_libs["nvml"]),
        },
    )

def _render_cudnn_template(repository_ctx, cudnn_config):
    cudnn_version = cudnn_config.cudnn_version
    if not cudnn_version:
        print("Can't find cuDNN installation. Creating dummy cuDNN rule.")
        cudnn_build_dummy = Label("//third_party/rules_cuda/cudnn:BUILD.dummy")
        repository_ctx.symlink(cudnn_build_dummy, "cudnn/BUILD")
        return

    cudnn_include_dir = cudnn_config.config["cudnn_include_dir"]

    # Select the headers based on the cuDNN version
    cudnn_headers = ["cudnn.h"]
    if cudnn_version.rsplit("_", 1)[-1] >= "8":
        cudnn_headers += [
            "cudnn_backend.h",
            "cudnn_adv_infer.h",
            "cudnn_adv_train.h",
            "cudnn_cnn_infer.h",
            "cudnn_cnn_train.h",
            "cudnn_ops_infer.h",
            "cudnn_ops_train.h",
            "cudnn_version.h",
        ]

    cudnn_srcs = ["{}/{}".format(cudnn_include_dir, header) for header in cudnn_headers]
    cudnn_outs = ["include/{}".format(header) for header in cudnn_headers]

    copy_rules = [
        make_copy_files_rule(
            repository_ctx,
            name = "cudnn-include",
            srcs = cudnn_srcs,
            outs = cudnn_outs,
        ),
    ]

    cudnn_libs = _find_cudnn_libs(repository_ctx, cudnn_config)
    cudnn_lib_srcs = []
    cudnn_lib_outs = []
    for path in cudnn_libs.values():
        cudnn_lib_srcs.append(path)
        cudnn_lib_outs.append("lib/" + paths.basename(path))

    copy_rules.append(make_copy_files_rule(
        repository_ctx,
        name = "cudnn-lib",
        srcs = cudnn_lib_srcs,
        outs = cudnn_lib_outs,
    ))

    repository_ctx.template(
        "cudnn/BUILD",
        _tpl_path(repository_ctx, "cudnn:BUILD"),
        {
            "%{copy_rules}": "\n\n".join(copy_rules),
            "%{cudnn_lib}": paths.basename(cudnn_libs["cudnn"]),
        },
    )

def _render_nccl_template(repository_ctx, nccl_config):
    nccl_version = nccl_config.nccl_version
    if not nccl_version:
        print("Can't find NCCL installation. Creating dummy NCCL rule.")
        nccl_build_dummy = Label("//third_party/rules_cuda/nccl:BUILD.dummy")
        repository_ctx.symlink(nccl_build_dummy, "nccl/BUILD")
    else:
        # Create target for locally installed NCCL.
        config_wrap = {
            "%{nccl_header_dir}": nccl_config.config["nccl_include_dir"],
            "%{nccl_library_dir}": nccl_config.config["nccl_library_dir"],
            "%{nccl_version}": nccl_version,
        }
        repository_ctx.template("nccl/BUILD", _tpl_path(repository_ctx, "nccl:system.BUILD"), config_wrap)

def _render_cuda_template(repository_ctx, cuda_config):
    # Create genrule to copy files from the installed CUDA toolkit into execroot.
    cuda_include_dir = cuda_config.config["cuda_include_dir"]
    copy_rules = [
        make_copy_dir_rule(
            repository_ctx,
            name = "cuda-include",
            src_dir = cuda_include_dir,
            out_dir = "include",
        ),
    ]

    cuda_libs = _find_cuda_libs(repository_ctx, cuda_config)
    cuda_lib_srcs = []
    cuda_lib_outs = []
    for path in cuda_libs.values():
        cuda_lib_srcs.append(path)
        cuda_lib_outs.append("lib/" + paths.basename(path))
    copy_rules.append(make_copy_files_rule(
        repository_ctx,
        name = "cuda-lib",
        srcs = cuda_lib_srcs,
        outs = cuda_lib_outs,
    ))

    repository_ctx.template(
        "cuda/BUILD",
        _tpl_path(repository_ctx, "cuda:BUILD"),
        {
            "%{copy_rules}": "\n\n".join(copy_rules),
            "%{cublasLt_lib}": paths.basename(cuda_libs["cublasLt"]),
            "%{cublas_lib}": paths.basename(cuda_libs["cublas"]),
            "%{cuda_driver_lib}": paths.basename(cuda_libs["cuda"]),
            "%{cudart_lib}": paths.basename(cuda_libs["cudart"]),
            "%{cudart_static_lib}": paths.basename(cuda_libs["cudart_static"]),
            "%{cufft_lib}": paths.basename(cuda_libs["cufft"]),
            "%{cupti_lib}": paths.basename(cuda_libs["cupti"]),
            "%{curand_lib}": paths.basename(cuda_libs["curand"]),
            "%{cusolver_lib}": paths.basename(cuda_libs["cusolver"]),
            "%{cusparse_lib}": paths.basename(cuda_libs["cusparse"]),
        },
    )

def _create_local_repository(repository_ctx):
    find_cuda_config_script = repository_ctx.path(Label("//third_party/rules_cuda:find_cuda_config.py"))
    cuda_config = _get_cuda_family_config(repository_ctx, find_cuda_config_script)

    _render_cuda_template(repository_ctx, cuda_config)
    _render_nvml_template(repository_ctx, cuda_config)
    _render_cudnn_template(repository_ctx, cuda_config)
    _render_nccl_template(repository_ctx, cuda_config)

def _local_config_cuda_impl(repository_ctx):
    # Path to CUDA Toolkit is
    # - taken from CUDA_PATH environment variable or
    # - determined through 'which ptxas' or
    # - defaults to '/usr/local/cuda'
    cuda_path = "/usr/local/cuda"
    ptxas_path = repository_ctx.which("ptxas")
    if ptxas_path:
        cuda_path = ptxas_path.dirname.dirname
    cuda_path = repository_ctx.os.environ.get("CUDA_PATH", cuda_path)
    if repository_ctx.path(cuda_path).exists:
        repository_ctx.file("BUILD")
        _create_local_repository(repository_ctx)
    else:
        print("Dummy @local_config_cuda repo as no CUDA installation found.")
        repository_ctx.file("BUILD")  # Empty file

local_config_cuda = repository_rule(
    implementation = _local_config_cuda_impl,
    environ = ["CUDA_PATH", "PATH"],
    local = True,
    configure = True,
)
