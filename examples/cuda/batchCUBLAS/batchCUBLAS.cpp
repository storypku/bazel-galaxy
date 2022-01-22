/**
 * Copyright 1993-2015 NVIDIA Corporation.  All rights reserved.
 *
 * Please refer to the NVIDIA end user license agreement (EULA) associated
 * with this source code for terms and conditions that govern your use of
 * this software. Any use, reproduction, disclosure, or distribution of
 * this software and related documentation outside the terms of the EULA
 * is strictly prohibited.
 *
 */

/*
 * This example demonstrates how to get better performance by
 * batching CUBLAS calls with the use of using streams
 */

#include "examples/cuda/batchCUBLAS/batchCUBLAS.h"

#include <cstdio>

//============================================================================================
// Device information utilities
//============================================================================================
#if defined(__cplusplus)
extern "C" {
#endif /* __cplusplus */

int getDeviceVersion(void) {
  int device;
  struct cudaDeviceProp properties;

  if (cudaGetDevice(&device) != cudaSuccess) {
    printf("failed to get device\n");
    return 0;
  }

  if (cudaGetDeviceProperties(&properties, device) != cudaSuccess) {
    printf("failed to get properties\n");
    return 0;
  }

  return properties.major * 100 + properties.minor * 10;
}

size_t getDeviceMemory(void) {
  struct cudaDeviceProp properties;
  int device;

  if (cudaGetDevice(&device) != cudaSuccess) {
    return 0;
  }

  if (cudaGetDeviceProperties(&properties, device) != cudaSuccess) {
    return 0;
  }

  return properties.totalGlobalMem;
}
#if defined(__cplusplus)
}
#endif /* __cplusplus */
