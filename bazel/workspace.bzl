load("//third_party/absl:workspace.bzl", absl = "repo")
load("//third_party/bazel_skylib:workspace.bzl", bazel_skylib = "repo")
load("//third_party/glog:workspace.bzl", glog = "repo")
load("//third_party/googletest:workspace.bzl", googletest = "repo")
load("//third_party/libjpeg:workspace.bzl", libjpeg = "repo")
load("//third_party/platforms:workspace.bzl", platforms = "repo")
load("//third_party/rules_boost:workspace.bzl", rules_boost = "repo")
load("//third_party/rules_cc:workspace.bzl", rules_cc = "repo")
load("//third_party/rules_cuda:workspace.bzl", rules_cuda = "repo")
load("//third_party/rules_docker:workspace.bzl", rules_docker = "repo")
load("//third_party/rules_fuzzing:workspace.bzl", rules_fuzzing = "repo")
load("//third_party/rules_python:workspace.bzl", rules_python = "repo")
load("//third_party/tcmalloc:workspace.bzl", tcmalloc = "repo")

def rules_bazel_repos():
    bazel_skylib()
    platforms()

def rules_lang_repos():
    rules_python()
    rules_cc()
    rules_cuda()
    rules_docker()

def third_party_repos():
    absl()
    glog(with_gflags = 0)
    googletest()
    rules_boost()

    rules_fuzzing()
    tcmalloc()

    libjpeg()

def galaxy_repositories():
    rules_bazel_repos()
    rules_lang_repos()
    third_party_repos()
