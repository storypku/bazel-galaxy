#pragma once

#include "absl/cleanup/cleanup.h"
#include "absl/time/clock.h"
#include "glog/logging.h"

#define TIME_IT(tag, msg)                                              \
  const auto tag##_start = absl::Now();                                \
  const absl::Cleanup cleanup##tag = [tag##_start] {                   \
    LOG(INFO) << msg << " takes "                                      \
              << absl::ToDoubleMilliseconds(absl::Now() - tag##_start) \
              << " ms";                                                \
  }
