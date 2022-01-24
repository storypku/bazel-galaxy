#include "examples/cuda/randomFog/rng.h"

#include <cstdio>

#include "gtest/gtest.h"

TEST(RngTest, TestRng) {
  RNG rng(12345, 1, 40000);
  rng.selectRng(RNG::Pseudo);

  float v = rng.getNextU01();
  printf("RNG::getNextU01: %.3f\n", v);

  v = rng.getNextU01();
  printf("RNG::getNextU01: %.3f\n", v);

  std::string msg;
  rng.getInfoString(msg);
  printf("Msg: %s\n", msg.c_str());
  EXPECT_FALSE(msg.empty()) << "Non-empty msg: " << msg;
}
