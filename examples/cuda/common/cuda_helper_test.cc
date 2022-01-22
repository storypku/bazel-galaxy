#include "examples/cuda/common/cuda_helper.h"

#include "cuda_runtime.h"
#include "gtest/gtest.h"

TEST(HelperCudaTest, TestFindCudaDevice) {
  EXPECT_GE(findCudaDevice(1, nullptr), 0);
}

TEST(HelperCudaTest, TestCheckCudaCapabilities) {
  EXPECT_TRUE(checkCudaCapabilities(3, 7));
}

TEST(HelperCudaTest, DISABLED_TestFindIntegratedGPU) {
  EXPECT_GE(findIntegratedGPU(), 0);
}
