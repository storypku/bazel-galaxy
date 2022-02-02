#!/usr/bin/env python3

import sys
import re
import subprocess

if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.stderr.write("Usage: find_clang_version.py <path/to/bin/clang>\n")
        sys.exit(1)

    clang_binary = sys.argv[1]

    command = [clang_binary, "--version"]

    result = subprocess.run(command,
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE)
    if result.returncode != 0:
        sys.stderr.write("Failed to run command '{}'\n{}".format(
            " ".join(command), result.stderr.decode("utf-8")))

    for line in result.stdout.decode("utf-8").strip().split("\n"):
        match = re.match("clang version (\d+\.\d+\.\d+)", line)
        if match:
            print(match.group(1))
            sys.exit(0)

    sys.stderr.write("Unable to determine clang version\n")
    sys.exit(1)
