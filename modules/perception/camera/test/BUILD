load("@rules_cc//cc:defs.bzl", "cc_library", "cc_test")
load("//tools:cpplint.bzl", "cpplint")

package(default_visibility = ["//visibility:public"])

cc_test(
    name = "camera_lib_lane_detector_denseline_lane_detector_test",
    size = "medium",
    srcs = ["camera_lib_lane_detector_denseline_lane_detector_test.cc"],
    deps = [
        "//cyber",
        "//modules/perception/base",
        "//modules/perception/camera/lib/lane/detector/denseline:denseline_lane_detector",
        "//modules/perception/common/io:io_util",
        "@com_google_googletest//:gtest_main",
        "@opencv//:core",
        "@opencv//:highgui",
        "@opencv//:imgcodecs",
        "@opencv//:imgproc",
    ],
)

cpplint()
