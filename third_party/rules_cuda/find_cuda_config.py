# Copyright 2019 The TensorFlow Authors. All Rights Reserved.
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
# ==============================================================================
"""Prints CUDA library and header directories and versions found on the system.

The script searches for CUDA library and header files on the system, inspects
them to determine their version and prints the configuration to stdout.
The paths to inspect and the required versions are specified through environment
variables. If no valid configuration is found, the script prints to stderr and
returns an error code.

The list of libraries to find is specified as arguments. Supported libraries are
CUDA (includes cuBLAS), cuDNN, NCCL, and TensorRT.

The script takes a list of base directories specified by the MY_CUDA_PATHS
environment variable as comma-separated glob list. The script looks for headers
and library files in a hard-coded set of subdirectories from these base paths.
If MY_CUDA_PATHS is not specified, a OS specific default is used:

  Linux:   /usr/local/cuda, /usr, and paths from 'ldconfig -p'.

Versions environment variables can be of the form 'x' or 'x.y' to request a
specific version, empty or unspecified to accept any version.

The output of a found library is of the form:
<library>_version: x.y.z
<library>_header_dir: ...
<library>_library_dir: ...
"""

import io
import os
import glob
import platform
import re
import subprocess
import sys

# pylint: disable=g-import-not-at-top
try:
    from shutil import which
except ImportError:
    from distutils.spawn import find_executable as which
# pylint: enable=g-import-not-at-top

_HEADER_REL_PATHS = [
    "",
    "include",
    "include/cuda",
    "include/*-linux-gnu",
    "extras/CUPTI/include",
    "include/cuda/CUPTI",
    "local/cuda/extras/CUPTI/include",
]

# Hard-coded set of relative paths to look for library files.
_LIBRARY_REL_PATHS = [
    "",
    "lib64",
    "lib",
    "lib/*-linux-gnu",
    "lib/x64",
    "extras/CUPTI/*",
    "local/cuda/lib64",
    "local/cuda/extras/CUPTI/lib64",
]

_SUPPORTED_PACKAGES = ["cuda", "cudnn", "nccl", "tensorrt"]

OK_GREEN = '\033[92m'
NO_COLOR = '\033[0m'


def debug(*args):
    print(OK_GREEN, "[debug]", *args, NO_COLOR, file=sys.stderr)


class ConfigError(Exception):
    pass


# Hard-coded set of relative paths to look for header files.


def _matches_version(actual_version, required_version):
    """Checks whether some version meets the requirements.

      All elements of the required_version need to be present in the
      actual_version.

          required_version  actual_version  result
          -----------------------------------------
          1                 1.1             True
          1.2               1               False
          1.2               1.3             False
                            1               True

      Args:
        required_version: The version specified by the user.
        actual_version: The version detected from the CUDA installation.
      Returns: Whether the actual version matches the required one.
  """
    if actual_version is None:
        return False

    # Strip spaces from the versions.
    actual_version = actual_version.strip()
    required_version = required_version.strip()
    return actual_version.startswith(required_version)


def _at_least_version(actual_version, required_version):
    actual = [int(v) for v in actual_version.split(".")]
    required = [int(v) for v in required_version.split(".")]
    return actual >= required


def _get_header_version(path, name):
    """Returns preprocessor defines in C header file."""
    for line in io.open(path, "r", encoding="utf-8").readlines():
        match = re.match("#define {} +(\d+)".format(name), line)
        if match:
            return match.group(1)
    return ""


def _cartesian_product(first, second):
    """Returns all path combinations of first and second."""
    return [os.path.join(f, s) for f in first for s in second]


def _not_found_error(base_paths, relative_paths, filepattern):
    base_paths = "".join(
        ["\n        '%s'" % path for path in sorted(base_paths)])
    relative_paths = "".join(
        ["\n        '%s'" % path for path in relative_paths])
    return ConfigError("Could not find any %s in any subdirectory:%s\nof:%s\n" %
                       (filepattern, relative_paths, base_paths))


def _find_file(base_paths, relative_paths, filepattern):
    for path in _cartesian_product(base_paths, relative_paths):
        candidates = glob.glob(os.path.join(path, filepattern))
        for file in candidates:
            return file
    raise _not_found_error(base_paths, relative_paths, filepattern)


def _find_library(base_paths, library_name, required_version):
    """Returns first valid path to the requested library, since only its dirname is considered in later use."""
    filepattern = ".".join(["lib" + library_name, "so"] +
                           required_version.split(".")[:1]) + "*"
    return _find_file(base_paths, _LIBRARY_REL_PATHS, filepattern)


def _find_versioned_file(base_paths, relative_paths, filepatterns,
                         required_version, get_version):
    """Returns first valid path to a file that matches the requested version."""
    if type(filepatterns) not in [list, tuple]:
        filepatterns = [filepatterns]
    for path in _cartesian_product(base_paths, relative_paths):
        for filepattern in filepatterns:
            for file in glob.glob(os.path.join(path, filepattern)):
                actual_version = get_version(file)
                if _matches_version(actual_version, required_version):
                    return file, actual_version

    message = ", ".join(filepatterns)
    if required_version:
        message += " matching version {}".format(required_version)

    raise _not_found_error(base_paths, relative_paths, message)


def _find_header(base_paths, header_name, get_version):
    """Returns first valid path to a header that matches the requested version."""
    return _find_versioned_file(base_paths, _HEADER_REL_PATHS, header_name, "",
                                get_version)


def _find_cuda_config(base_paths):

    def get_header_version(path):
        version = int(_get_header_version(path, "CUDA_VERSION"))
        if not version:
            return None
        return "%d.%d" % (version // 1000, version % 1000 // 10)

    cuda_header_path, header_version = _find_header(base_paths, "cuda.h",
                                                    get_header_version)
    cuda_version = header_version  # x.y, see above.

    cuda_library_path = _find_library(base_paths, "cudart", cuda_version)

    def get_nvcc_version(path):
        pattern = "Cuda compilation tools, release \d+\.\d+, V(\d+\.\d+\.\d+)"
        for line in subprocess.check_output([path, "--version"]).splitlines():
            match = re.match(pattern, line.decode("ascii"))
            if match:
                return match.group(1)
        return None

    nvcc_name = "nvcc"
    nvcc_path, nvcc_version = _find_versioned_file(base_paths, [
        "",
        "bin",
        "local/cuda/bin",
    ], nvcc_name, cuda_version, get_nvcc_version)

    nvvm_path = _find_file(base_paths, [
        "nvvm/libdevice",
        "share/cuda",
        "lib/nvidia-cuda-toolkit/libdevice",
        "local/cuda/nvvm/libdevice",
    ], "libdevice*.10.bc")
    debug("nvvm path: {}".format(nvvm_path))

    cupti_header_path = _find_file(base_paths, _HEADER_REL_PATHS, "cupti.h")
    cupti_library_path = _find_library(base_paths, "cupti", "")

    cuda_binary_dir = os.path.dirname(nvcc_path)
    nvvm_library_dir = os.path.dirname(nvvm_path)

    # XLA requires the toolkit path to find ptxas and libdevice.
    # TODO(csigg): pass in both directories instead.
    cuda_toolkit_paths = (
        os.path.normpath(os.path.join(cuda_binary_dir, "..")),
        os.path.normpath(os.path.join(nvvm_library_dir, "../..")),
    )

    if cuda_toolkit_paths[0] != cuda_toolkit_paths[1]:
        raise ConfigError("Inconsistent CUDA toolkit path: %s vs %s" %
                          cuda_toolkit_paths)

    return {
        "cuda_version": cuda_version,
        "cuda_include_dir": os.path.dirname(cuda_header_path),
        "cuda_library_dir": os.path.dirname(cuda_library_path),
        "cuda_binary_dir": cuda_binary_dir,
        "nvvm_library_dir": nvvm_library_dir,
        "cupti_include_dir": os.path.dirname(cupti_header_path),
        "cupti_library_dir": os.path.dirname(cupti_library_path),
        "cuda_toolkit_path": cuda_toolkit_paths[0],
    }


def _find_cublas_config(base_paths, cuda_version):

    if _at_least_version(cuda_version, "10.1"):

        def get_header_version(path):
            version = (_get_header_version(path, name)
                       for name in ("CUBLAS_VER_MAJOR", "CUBLAS_VER_MINOR",
                                    "CUBLAS_VER_PATCH"))
            return ".".join(version)

        header_path, header_version = _find_header(base_paths, "cublas_api.h",
                                                   get_header_version)
        # cuBLAS uses the major version only.
        cublas_version = header_version.split(".")[0]
    else:
        # There is no version info available before CUDA 10.1, just find the file.
        header_version = cuda_version
        header_path = _find_file(base_paths, _HEADER_REL_PATHS, "cublas_api.h")
        # cuBLAS version is the same as CUDA version (x.y).
        cublas_version = cuda_version

    library_path = _find_library(base_paths, "cublas", cublas_version)
    debug("cublas: version={}, header={}, library={}".format(
        header_version, header_path, library_path))

    return {
        "cublas_version": header_version,
        "cublas_include_dir": os.path.dirname(header_path),
        "cublas_library_dir": os.path.dirname(library_path),
    }


def _find_cusolver_config(base_paths, cuda_version):

    if _at_least_version(cuda_version, "11.0"):

        def get_header_version(path):
            version = (_get_header_version(path, name)
                       for name in ("CUSOLVER_VER_MAJOR", "CUSOLVER_VER_MINOR",
                                    "CUSOLVER_VER_PATCH"))
            return ".".join(version)

        header_path, header_version = _find_header(base_paths,
                                                   "cusolver_common.h",
                                                   get_header_version)
        cusolver_version = header_version.split(".")[0]

    else:
        header_version = cuda_version
        header_path = _find_file(base_paths, _HEADER_REL_PATHS,
                                 "cusolver_common.h")
        cusolver_version = cuda_version

    library_path = _find_library(base_paths, "cusolver", cusolver_version)
    debug("cusolver: version={} header={}, library={}".format(
        cusolver_version, header_path, library_path))

    return {
        "cusolver_version": header_version,
        "cusolver_include_dir": os.path.dirname(header_path),
        "cusolver_library_dir": os.path.dirname(library_path),
    }


def _find_curand_config(base_paths, cuda_version):

    if _at_least_version(cuda_version, "11.0"):

        def get_header_version(path):
            version = (_get_header_version(path, name)
                       for name in ("CURAND_VER_MAJOR", "CURAND_VER_MINOR",
                                    "CURAND_VER_PATCH"))
            return ".".join(version)

        header_path, header_version = _find_header(base_paths, "curand.h",
                                                   get_header_version)
        curand_version = header_version.split(".")[0]

    else:
        header_version = cuda_version
        header_path = _find_file(base_paths, _HEADER_REL_PATHS, "curand.h")
        curand_version = cuda_version

    library_path = _find_library(base_paths, "curand", curand_version)
    debug("curand: version={}, header={}, library={}".format(
        header_version, header_path, library_path))

    return {
        "curand_version": header_version,
        "curand_include_dir": os.path.dirname(header_path),
        "curand_library_dir": os.path.dirname(library_path),
    }


def _find_cufft_config(base_paths, cuda_version):

    if _at_least_version(cuda_version, "11.0"):

        def get_header_version(path):
            version = (_get_header_version(path, name)
                       for name in ("CUFFT_VER_MAJOR", "CUFFT_VER_MINOR",
                                    "CUFFT_VER_PATCH"))
            return ".".join(version)

        header_path, header_version = _find_header(base_paths, "cufft.h",
                                                   get_header_version)
        cufft_version = header_version.split(".")[0]

    else:
        header_version = cuda_version
        header_path = _find_file(base_paths, _HEADER_REL_PATHS, "cufft.h")
        cufft_version = cuda_version

    library_path = _find_library(base_paths, "cufft", cufft_version)
    debug("cufft: version={}, header={} library={}".format(
        header_version, header_path, library_path))

    return {
        "cufft_version": header_version,
        "cufft_include_dir": os.path.dirname(header_path),
        "cufft_library_dir": os.path.dirname(library_path),
    }


def _find_cusparse_config(base_paths, cuda_version):

    if _at_least_version(cuda_version, "11.0"):

        def get_header_version(path):
            version = (_get_header_version(path, name)
                       for name in ("CUSPARSE_VER_MAJOR", "CUSPARSE_VER_MINOR",
                                    "CUSPARSE_VER_PATCH"))
            return ".".join(version)

        header_path, header_version = _find_header(base_paths, "cusparse.h",
                                                   get_header_version)
        cusparse_version = header_version.split(".")[0]

    else:
        header_version = cuda_version
        header_path = _find_file(base_paths, _HEADER_REL_PATHS, "cusparse.h")
        cusparse_version = cuda_version

    library_path = _find_library(base_paths, "cusparse", cusparse_version)
    debug("cusparse: version={}, header={} library={}".format(
        header_version, header_path, library_path))

    return {
        "cusparse_version": header_version,
        "cusparse_include_dir": os.path.dirname(header_path),
        "cusparse_library_dir": os.path.dirname(library_path),
    }


def _find_nvml_config(base_paths, cuda_version):

    def get_header_version(path):
        return _get_header_version(path, "NVML_API_VERSION")

    header_path, header_version = _find_header(base_paths, "nvml.h",
                                               get_header_version)
    query_cmd = [
        "nvidia-smi", "--query-gpu=driver_version", "--format=csv,noheader"
    ]
    driver_version = subprocess.check_output(query_cmd).decode("ascii").strip()

    library_path = _find_library(base_paths, "nvidia-ml", driver_version)
    debug("nvml: api_version={}, driver_version={}".format(
        header_version, driver_version))
    debug("nvml: header={}, library={}".format(header_path, library_path))

    return {
        "nvml_version": header_version,
        "nvml_driver_version": driver_version,
        "nvml_include_dir": os.path.dirname(header_path),
        "nvml_library_dir": os.path.dirname(library_path),
    }


def _find_nvjpeg_config(base_paths, cuda_version):

    if _at_least_version(cuda_version, "11.0"):

        def get_header_version(path):
            version = (_get_header_version(path, name)
                       for name in ("NVJPEG_VER_MAJOR", "NVJPEG_VER_MINOR",
                                    "NVJPEG_VER_PATCH"))
            return ".".join(version)

        header_path, header_version = _find_header(base_paths, "nvjpeg.h",
                                                   get_header_version)
        cusparse_version = header_version.split(".")[0]

    else:  #TODO(storypku): to be checked on Xavier w/ CUDA 10.2
        header_version = cuda_version
        header_path = _find_file(base_paths, _HEADER_REL_PATHS, "nvjpeg.h")
        cusparse_version = cuda_version

    library_path = _find_library(base_paths, "nvjpeg", cusparse_version)
    debug("nvjpeg: version={}, header={} library={}".format(
        header_version, header_path, library_path))

    return {
        "nvjpeg_version": header_version,
        "nvjpeg_include_dir": os.path.dirname(header_path),
        "nvjpeg_library_dir": os.path.dirname(library_path),
    }


def _find_npp_config(base_paths, cuda_version):

    if _at_least_version(cuda_version, "11.0"):

        def get_header_version(path):
            version = (_get_header_version(path, name)
                       for name in ("NPP_VER_MAJOR", "NPP_VER_MINOR",
                                    "NPP_VER_PATCH"))
            return ".".join(version)

        header_path, header_version = _find_header(base_paths, "npp.h",
                                                   get_header_version)
        cusparse_version = header_version.split(".")[0]

    else:  # TODO(storypku): to be checked on Xavier w/ CUDA 10.2
        header_version = cuda_version
        header_path = _find_file(base_paths, _HEADER_REL_PATHS, "npp.h")
        cusparse_version = cuda_version

    # nppc/nppial/nppicc/nppidei/nppif/nppig/nppim/nppist/nppisu/nppitc/npps
    library_path = _find_library(base_paths, "nppc", cusparse_version)
    debug("npp: version={}, header={} library={}".format(
        header_version, header_path, library_path))

    return {
        "npp_version": header_version,
        "npp_include_dir": os.path.dirname(header_path),
        "npp_library_dir": os.path.dirname(library_path),
    }


def _find_cudnn_config(base_paths):

    def get_header_version(path):
        version = [
            _get_header_version(path, name)
            for name in ("CUDNN_MAJOR", "CUDNN_MINOR", "CUDNN_PATCHLEVEL")
        ]
        return ".".join(version) if version[0] else None

    header_path, header_version = _find_header(base_paths,
                                               ("cudnn.h", "cudnn_version.h"),
                                               get_header_version)
    cudnn_version = header_version.split(".")[0]

    library_path = _find_library(base_paths, "cudnn", cudnn_version)
    debug("cudnn, version={}, header={}, library={}".format(
        header_version, header_path, library_path))

    return {
        "cudnn_version": cudnn_version,
        "cudnn_include_dir": os.path.dirname(header_path),
        "cudnn_library_dir": os.path.dirname(library_path),
    }


def _find_nccl_config(base_paths):

    def get_header_version(path):
        version = (_get_header_version(path, name)
                   for name in ("NCCL_MAJOR", "NCCL_MINOR", "NCCL_PATCH"))
        return ".".join(version)

    header_path, header_version = _find_header(base_paths, "nccl.h",
                                               get_header_version)
    nccl_version = header_version.split(".")[0]

    library_path = _find_library(base_paths, "nccl", nccl_version)
    debug("nccl: version={}, header={}, library={}".format(
        header_version, header_path, library_path))

    return {
        "nccl_version": nccl_version,
        "nccl_include_dir": os.path.dirname(header_path),
        "nccl_library_dir": os.path.dirname(library_path),
    }


def _find_tensorrt_config(base_paths):

    def get_header_version(path):
        version = (_get_header_version(path, name)
                   for name in ("NV_TENSORRT_MAJOR", "NV_TENSORRT_MINOR",
                                "NV_TENSORRT_PATCH"))
        # `version` is a generator object, so we convert it to a list before using
        # it (muitiple times below).
        version = list(version)
        if not all(version):
            return None  # Versions not found, make _matches_version returns False.
        return ".".join(version)

    header_path, header_version = _find_header(base_paths, "NvInferVersion.h",
                                               get_header_version)

    tensorrt_version = header_version.split(".")[0]
    library_path = _find_library(base_paths, "nvinfer", tensorrt_version)
    debug("tensorrt: version={}, header={}, library={}".format(
        header_version, header_path, library_path))

    return {
        "tensorrt_version": tensorrt_version,
        "tensorrt_include_dir": os.path.dirname(header_path),
        "tensorrt_library_dir": os.path.dirname(library_path),
    }


def _determine_cuda_path():
    # NOTE(storypku): Be consistent with the behavior of @local_cuda
    cuda_path = os.environ.get("CUDA_PATH", "")
    if not cuda_path:
        ptxas_path = which("ptxas")
        if ptxas_path:
            cuda_path = os.path.normpath(os.path.join(ptxas_path, "../.."))
    if not cuda_path:
        cuda_path = "/usr/local/cuda"
    return cuda_path


def _determine_cuda_search_paths():
    cuda_path = _determine_cuda_path()
    env_var = os.environ.get("MY_CUDA_PATHS", "")
    candidates = []
    if env_var:
        candidates = env_var.split(",")
        if cuda_path not in candidates:
            raise ConfigError(
                "Inconsistent CUDA toolkit path: {} not in candidates = {}".
                format(cuda_path, candidates))
    else:
        candidates = ["/usr/local/cuda", "/usr"]
        if candidates[0] != cuda_path:
            candidates = [cuda_path] + candidates
    return [path for path in candidates if os.path.exists(path)]


def _parse_cmdline_args():
    libraries = [argv.lower() for argv in sys.argv[1:]]
    for lib in libraries:
        if lib not in _SUPPORTED_PACKAGES:
            raise ConfigError("Package {} is not supported.".format(lib))

    return libraries


def find_cuda_config():
    """Returns a dictionary of CUDA library and header file paths."""

    libraries = _parse_cmdline_args()
    base_paths = _determine_cuda_search_paths()

    result = {}
    if "cuda" in libraries:
        result.update(_find_cuda_config(base_paths))
        cuda_version = result["cuda_version"]
        result.update(_find_cublas_config(base_paths, cuda_version))
        result.update(_find_cusolver_config(base_paths, cuda_version))
        result.update(_find_curand_config(base_paths, cuda_version))
        result.update(_find_cufft_config(base_paths, cuda_version))
        result.update(_find_cusparse_config(base_paths, cuda_version))

        if platform.machine() == "x86_64":
            result.update(_find_nvml_config(base_paths, cuda_version))
            result.update(_find_nvjpeg_config(base_paths, cuda_version))

        result.update(_find_npp_config(base_paths, cuda_version))

    if "cudnn" in libraries:
        result.update(_find_cudnn_config(base_paths))

    if "nccl" in libraries:
        result.update(_find_nccl_config(base_paths))

    if "tensorrt" in libraries:
        result.update(_find_tensorrt_config(base_paths))

    for k, v in result.items():
        if k.endswith("_dir") or k.endswith("_path"):
            result[k] = os.path.realpath(v)

    return result


def main():
    try:
        for key, value in sorted(find_cuda_config().items()):
            print("{}: {}".format(key, value))
    except ConfigError as e:
        sys.stderr.write(str(e) + '\n')
        sys.exit(1)


if __name__ == "__main__":
    main()
