#include <cstdio>

#include "examples/cuda/hello/kernel.h"

namespace {

void HelloFromHost() { std::printf("Hello from Host\n"); }

}  // namespace

int main(int argc, char* argv[]) {
  HelloFromHost();
  HelloFromCuda();
  return 0;
}
