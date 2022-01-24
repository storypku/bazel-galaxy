#include "examples/cuda/common/cusolver_helper.h"

#include <ctype.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>

#include "cuda/include/cuda_runtime.h"

const char* _cudaGetErrorEnum(cusolverStatus_t error) {
  switch (error) {
    case CUSOLVER_STATUS_SUCCESS:
      return "CUSOLVER_STATUS_SUCCESS";
    case CUSOLVER_STATUS_NOT_INITIALIZED:
      return "CUSOLVER_STATUS_NOT_INITIALIZED";
    case CUSOLVER_STATUS_ALLOC_FAILED:
      return "CUSOLVER_STATUS_ALLOC_FAILED";
    case CUSOLVER_STATUS_INVALID_VALUE:
      return "CUSOLVER_STATUS_INVALID_VALUE";
    case CUSOLVER_STATUS_ARCH_MISMATCH:
      return "CUSOLVER_STATUS_ARCH_MISMATCH";
    case CUSOLVER_STATUS_MAPPING_ERROR:
      return "CUSOLVER_STATUS_MAPPING_ERROR";
    case CUSOLVER_STATUS_EXECUTION_FAILED:
      return "CUSOLVER_STATUS_EXECUTION_FAILED";
    case CUSOLVER_STATUS_INTERNAL_ERROR:
      return "CUSOLVER_STATUS_INTERNAL_ERROR";
    case CUSOLVER_STATUS_MATRIX_TYPE_NOT_SUPPORTED:
      return "CUSOLVER_STATUS_MATRIX_TYPE_NOT_SUPPORTED";
    case CUSOLVER_STATUS_NOT_SUPPORTED:
      return "CUSOLVER_STATUS_NOT_SUPPORTED ";
    case CUSOLVER_STATUS_ZERO_PIVOT:
      return "CUSOLVER_STATUS_ZERO_PIVOT";
    case CUSOLVER_STATUS_INVALID_LICENSE:
      return "CUSOLVER_STATUS_INVALID_LICENSE";
    default:
      break;
  }

  return "<unknown>";
}

double vec_norminf(int n, const double* x) {
  double norminf = 0;
  for (int j = 0; j < n; j++) {
    double x_abs = fabs(x[j]);
    norminf = (norminf > x_abs) ? norminf : x_abs;
  }
  return norminf;
}

/*
 * |A| = max { |A|*ones(m,1) }
 */
double mat_norminf(int m, int n, const double* A, int lda) {
  double norminf = 0;
  for (int i = 0; i < m; i++) {
    double sum = 0.0;
    for (int j = 0; j < n; j++) {
      double A_abs = fabs(A[i + j * lda]);
      sum += A_abs;
    }
    norminf = (norminf > sum) ? norminf : sum;
  }
  return norminf;
}

/*
 * |A| = max { |A|*ones(m,1) }
 */
double csr_mat_norminf(int m, int n, int nnzA, const cusparseMatDescr_t descrA,
                       const double* csrValA, const int* csrRowPtrA,
                       const int* csrColIndA) {
  const int baseA =
      (CUSPARSE_INDEX_BASE_ONE == cusparseGetMatIndexBase(descrA)) ? 1 : 0;

  double norminf = 0;
  for (int i = 0; i < m; i++) {
    double sum = 0.0;
    const int start = csrRowPtrA[i] - baseA;
    const int end = csrRowPtrA[i + 1] - baseA;
    for (int colidx = start; colidx < end; colidx++) {
      // const int j = csrColIndA[colidx] - baseA;
      double A_abs = fabs(csrValA[colidx]);
      sum += A_abs;
    }
    norminf = (norminf > sum) ? norminf : sum;
  }
  return norminf;
}

void display_matrix(int m, int n, int nnzA, const cusparseMatDescr_t descrA,
                    const double* csrValA, const int* csrRowPtrA,
                    const int* csrColIndA) {
  const int baseA =
      (CUSPARSE_INDEX_BASE_ONE == cusparseGetMatIndexBase(descrA)) ? 1 : 0;

  printf("m = %d, n = %d, nnz = %d, matlab base-1\n", m, n, nnzA);

  for (int row = 0; row < m; row++) {
    const int start = csrRowPtrA[row] - baseA;
    const int end = csrRowPtrA[row + 1] - baseA;
    for (int colidx = start; colidx < end; colidx++) {
      const int col = csrColIndA[colidx] - baseA;
      double Areg = csrValA[colidx];
      printf("A(%d, %d) = %20.16E\n", row + 1, col + 1, Areg);
    }
  }
}

double second(void) {
  struct timeval tv;
  gettimeofday(&tv, NULL);
  return (double)tv.tv_sec + (double)tv.tv_usec / 1000000.0;
}
