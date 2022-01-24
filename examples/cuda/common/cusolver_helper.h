/*
 * Copyright 2015 NVIDIA Corporation.  All rights reserved.
 *
 * Please refer to the NVIDIA end user license agreement (EULA) associated
 * with this source code for terms and conditions that govern your use of
 * this software. Any use, reproduction, disclosure, or distribution of
 * this software and related documentation outside the terms of the EULA
 * is strictly prohibited.
 *
 */
#pragma once

#include "cuda/include/cusolver_common.h"
#include "cuda/include/cusparse.h"

const char* _cudaGetErrorEnum(cusolverStatus_t error);

struct CuSolverTestOpts {
  char* sparse_mat_filename;  // by switch -F<filename>
  const char* testFunc;       // by switch -R<name>
  const char* reorder;        // by switch -P<name>
  int lda;                    // by switch -lda<int>
};

double vec_norminf(int n, const double* x);

/*
 * |A| = max { |A|*ones(m,1) }
 */
double mat_norminf(int m, int n, const double* A, int lda);

/*
 * |A| = max { |A|*ones(m,1) }
 */
double csr_mat_norminf(int m, int n, int nnzA, const cusparseMatDescr_t descrA,
                       const double* csrValA, const int* csrRowPtrA,
                       const int* csrColIndA);

void display_matrix(int m, int n, int nnzA, const cusparseMatDescr_t descrA,
                    const double* csrValA, const int* csrRowPtrA,
                    const int* csrColIndA);

double second(void);
