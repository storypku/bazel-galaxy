#include <cstdio>

#include "cuda_runtime_api.h"
#include "examples/cuda/hello/kernel.h"

namespace {

__global__ void Hello() { std::printf("Hello World from GPU!\n"); }

void ReportIfError(cudaError_t error) {
  if (error != cudaSuccess) {
    std::fprintf(stderr, "CUDA error: %s\n", cudaGetErrorString(error));
  }
}

}  // namespace

void HelloFromCuda() {
  Hello<<<1, 1>>>();

  ReportIfError(cudaGetLastError());
  ReportIfError(cudaDeviceSynchronize());
}
