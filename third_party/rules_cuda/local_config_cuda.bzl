def _create_local_repository(repository_ctx, cuda_path):
    pass

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
        _create_local_repository(repository_ctx, cuda_path)
    else:
        repository_ctx.file("BUILD")  # Empty file

local_config_cuda = repository_rule(
    implementation = _local_config_cuda_impl,
    environ = ["CUDA_PATH", "PATH"],
    local = True,
    # remotable = True,
)
