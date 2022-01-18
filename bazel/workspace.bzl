load("//third_party/absl:workspace.bzl", absl = "repo")
load("//third_party/glog:workspace.bzl", glog = "repo")
load("//third_party/rules_fuzzing:workspace.bzl", rules_fuzzing = "repo")
load("//third_party/tcmalloc:workspace.bzl", tcmalloc = "repo")

def galaxy_repositories():
    absl()
    glog(with_gflags = 0)
    rules_fuzzing()
    tcmalloc()
