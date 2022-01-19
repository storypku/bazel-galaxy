workspace(name = "com_github_story_bazel_galaxy")

load("//bazel:workspace.bzl", "galaxy_repositories")

galaxy_repositories()

load("//bazel:deps.bzl", "galaxy_dependencies")

galaxy_dependencies()

load("@rules_fuzzing//fuzzing:init.bzl", "rules_fuzzing_init")

rules_fuzzing_init()
