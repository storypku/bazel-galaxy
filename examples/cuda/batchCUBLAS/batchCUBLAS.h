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

#include <math.h>
#include <stdlib.h>

#include "cuda/include/cublas_v2.h"
#include "cuda_runtime.h"

#define SWITCH_CHAR '-'

#define REFFUNC(funcname) ref_##funcname
#define TESTGEN(funcname) get_##funcname##_params
#define TESTPARAMS(funcname) funcname##TestParams

#define DEV_VER_DBL_SUPPORT (130)
#define DEV_VER_ALL_SUPPORT (999)

/* Errors Tests to be returned by all the Cublas test */
#define CUBLASTEST_PASSED 0
#define CUBLASTEST_FAILED 1
#define CUBLASTEST_WAIVED 2

//============================================================================================
// Device information utilities
//============================================================================================

#if defined(__cplusplus)
extern "C" {
#endif /* __cplusplus */
int getDeviceVersion(void);
size_t getDeviceMemory(void);
#if defined(__cplusplus)
}
#endif /* __cplusplus */

//============================================================================================
// Math utilities
//============================================================================================

static __inline__ int imax(int x, int y) { return (x > y) ? x : y; }

static __inline__ unsigned floatAsUInt(float x) {
  volatile union {
    float f;
    unsigned i;
  } xx;
  xx.f = x;
  return xx.i;
}

static __inline__ unsigned long long doubleAsULL(double x) {
  volatile union {
    double f;
    unsigned long long i;
  } xx;
  xx.f = x;
  return xx.i;
}

static __inline__ unsigned cuRand(void) {
  /* George Marsaglia's fast inline random number generator */
#define CUDA_ZNEW (cuda_z = 36969 * (cuda_z & 65535) + (cuda_z >> 16))
#define CUDA_WNEW (cuda_w = 18000 * (cuda_w & 65535) + (cuda_w >> 16))
#define CUDA_MWC ((CUDA_ZNEW << 16) + CUDA_WNEW)
#define CUDA_SHR3                          \
  (cuda_jsr = cuda_jsr ^ (cuda_jsr << 17), \
   cuda_jsr = cuda_jsr ^ (cuda_jsr >> 13), \
   cuda_jsr = cuda_jsr ^ (cuda_jsr << 5))
#define CUDA_CONG (cuda_jcong = 69069 * cuda_jcong + 1234567)
#define KISS ((CUDA_MWC ^ CUDA_CONG) + CUDA_SHR3)
  static unsigned int cuda_z = 362436069, cuda_w = 521288629;
  static unsigned int cuda_jsr = 123456789, cuda_jcong = 380116160;
  return KISS;
}

//============================================================================================
// cuGet and cuEqual versions
//============================================================================================

template <typename T_ELEM>
__inline__ __device__ __host__ T_ELEM cuGet(double);
template <>
__inline__ __device__ __host__ float cuGet<float>(double x) {
  return float(x);
}
template <>
__inline__ __device__ __host__ double cuGet<double>(double x) {
  return double(x);
}

template <typename T_ELEM>
__inline__ __device__ __host__ T_ELEM cuGet(double, double);
template <>
__inline__ __device__ __host__ float cuGet<float>(double x, double y) {
  return float(x);
}
template <>
__inline__ __device__ __host__ double cuGet<double>(double x, double y) {
  return double(x);
}
static __inline__ __device__ __host__ bool cuEqual(float x, float y) {
  return (x == y);
}
static __inline__ __device__ __host__ bool cuEqual(double x, double y) {
  return (x == y);
}

//============================================================================================
// Platform dependent timing utility
//============================================================================================

#if defined(__linux__) || defined(__QNX__)
#include <stddef.h>
#include <sys/resource.h>
#include <sys/time.h>
static double second(void) {
  struct timeval tv;
  gettimeofday(&tv, NULL);
  return (double)tv.tv_sec + (double)tv.tv_usec / 1000000.0;
}
#else
#error unsupported platform
#endif
