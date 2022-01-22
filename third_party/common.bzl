def read_dir(repository_ctx, src_dir):
    """Returns a sorted list with all files in a directory.

    Finds all files inside a directory, traversing subfolders and following
    symlinks.

    Args:
      repository_ctx: the repository_ctx
      src_dir: the directory to traverse

    Returns:
      A sorted list with all files in a directory.
    """
    find_result = execute(
        repository_ctx,
        ["find", src_dir, "-follow", "-type", "f"],
        allow_failure = True,
    )
    result = find_result.stdout
    return sorted(result.splitlines())

def execute(
        repository_ctx,
        cmdline,
        allow_failure = False):
    """Executes an arbitrary shell command.

    Args:
      repository_ctx: the repository_ctx object
      cmdline: list of strings, the command to execute
      allow_failure: bool, if True, an empty stdout result and output to stderr
        is fine, otherwise it's an error
    Returns:
      The result of repository_ctx.execute(cmdline)
    """
    result = repository_ctx.execute(cmdline)
    if (result.return_code != 0 or not result.stdout) and not allow_failure:
        fail(
            "\n".join([
                result.stderr.strip(),
            ]),
        )
    return result

def err_out(result):
    """Returns stderr if set, else stdout.

    This function is a workaround for a bug in RBE where stderr is returned as stdout. Instead
    of using result.stderr use err_out(result) instead.

    Args:
      result: the exec_result.

    Returns:
      The stderr if set, else stdout
    """
    if len(result.stderr) == 0:
        return result.stdout
    return result.stderr
