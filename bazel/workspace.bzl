load("//third_party/absl:workspace.bzl", absl = "repo")
load("//third_party/rules_fuzzing:workspace.bzl", rules_fuzzing = "repo")
load("//third_party/tcmalloc:workspace.bzl", tcmalloc = "repo")

def galaxy_repositories():
    absl()
    rules_fuzzing()
    tcmalloc()
