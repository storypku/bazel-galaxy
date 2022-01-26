load("@rules_cc//cc:defs.bzl", "cc_binary", "cc_library", "cc_test")

package(default_visibility = ["//visibility:public"])

cc_library(
    name = "bus_schedule",
    srcs = ["bus_schedule.cc"],
    hdrs = ["bus_schedule.h"],
    deps = [
        "@boost//:serialization",
        "@com_google_absl//absl/status",
        "@com_google_absl//absl/status:statusor",
    ],
)

cc_test(
    name = "bus_schedule_test",
    size = "small",
    srcs = ["bus_schedule_test.cc"],
    deps = [
        ":bus_schedule",
        "@com_google_googletest//:gtest_main",
    ],
)

cc_binary(
    name = "bus_schedule_demo",
    srcs = ["bus_schedule_demo.cc"],
    deps = [
        ":bus_schedule",
    ],
)
