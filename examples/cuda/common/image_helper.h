/* Copyright (c) 2022, NVIDIA CORPORATION. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of NVIDIA CORPORATION nor the names of its
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

// These are helper functions for the SDK samples (image,bitmap)
#pragma once

#include <assert.h>
#include <math.h>
#include <stdint.h>

#include <algorithm>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

#include "examples/cuda/common/cuda_helper.h"

// namespace unnamed (internal)
namespace helper_image_internal {
//! size of PGM file header
const unsigned int PGMHeaderSize = 0x40;

// types

//! Data converter from unsigned char / unsigned byte to type T
template <class T>
struct ConverterFromUByte;

//! Data converter from unsigned char / unsigned byte
template <>
struct ConverterFromUByte<unsigned char> {
  //! Conversion operator
  //! @return converted value
  //! @param  val  value to convert
  float operator()(const unsigned char& val) {
    return static_cast<unsigned char>(val);
  }
};

//! Data converter from unsigned char / unsigned byte to float
template <>
struct ConverterFromUByte<float> {
  //! Conversion operator
  //! @return converted value
  //! @param  val  value to convert
  float operator()(const unsigned char& val) {
    return static_cast<float>(val) / 255.0f;
  }
};

//! Data converter from unsigned char / unsigned byte to type T
template <class T>
struct ConverterToUByte;

//! Data converter from unsigned char / unsigned byte to unsigned int
template <>
struct ConverterToUByte<unsigned char> {
  //! Conversion operator (essentially a passthru
  //! @return converted value
  //! @param  val  value to convert
  unsigned char operator()(const unsigned char& val) { return val; }
};

//! Data converter from unsigned char / unsigned byte to unsigned int
template <>
struct ConverterToUByte<float> {
  //! Conversion operator
  //! @return converted value
  //! @param  val  value to convert
  unsigned char operator()(const float& val) {
    return static_cast<unsigned char>(val * 255.0f);
  }
};
}  // namespace helper_image_internal

#if defined(__linux__)
#ifndef FOPEN
#define FOPEN(fHandle, filename, mode) (fHandle = fopen(filename, mode))
#endif
#ifndef FOPEN_FAIL
#define FOPEN_FAIL(result) (result == NULL)
#endif
#ifndef SSCANF
#define SSCANF sscanf
#endif
#else
#error Unsupported platform
#endif

inline bool __loadPPM(const char* file, unsigned char** data, unsigned int* w,
                      unsigned int* h, unsigned int* channels) {
  FILE* fp = NULL;

  if (FOPEN_FAIL(FOPEN(fp, file, "rb"))) {
    std::cerr << "__LoadPPM() : Failed to open file: " << file << std::endl;
    return false;
  }

  // check header
  char header[helper_image_internal::PGMHeaderSize];

  if (fgets(header, helper_image_internal::PGMHeaderSize, fp) == NULL) {
    std::cerr << "__LoadPPM() : reading PGM header returned NULL" << std::endl;
    return false;
  }

  if (strncmp(header, "P5", 2) == 0) {
    *channels = 1;
  } else if (strncmp(header, "P6", 2) == 0) {
    *channels = 3;
  } else {
    std::cerr << "__LoadPPM() : File is not a PPM or PGM image" << std::endl;
    *channels = 0;
    return false;
  }

  // parse header, read maxval, width and height
  unsigned int width = 0;
  unsigned int height = 0;
  unsigned int maxval = 0;
  unsigned int i = 0;

  while (i < 3) {
    if (fgets(header, helper_image_internal::PGMHeaderSize, fp) == NULL) {
      std::cerr << "__LoadPPM() : reading PGM header returned NULL"
                << std::endl;
      return false;
    }

    if (header[0] == '#') {
      continue;
    }

    if (i == 0) {
      i += SSCANF(header, "%u %u %u", &width, &height, &maxval);
    } else if (i == 1) {
      i += SSCANF(header, "%u %u", &height, &maxval);
    } else if (i == 2) {
      i += SSCANF(header, "%u", &maxval);
    }
  }

  // check if given handle for the data is initialized
  if (NULL != *data) {
    if (*w != width || *h != height) {
      std::cerr << "__LoadPPM() : Invalid image dimensions." << std::endl;
    }
  } else {
    *data = (unsigned char*)malloc(sizeof(unsigned char) * width * height *
                                   *channels);
    *w = width;
    *h = height;
  }

  // read and close file
  if (fread(*data, sizeof(unsigned char), width * height * *channels, fp) ==
      0) {
    std::cerr << "__LoadPPM() read data returned error." << std::endl;
  }

  fclose(fp);

  return true;
}

inline bool __savePPM(const char* file, unsigned char* data, unsigned int w,
                      unsigned int h, unsigned int channels) {
  assert(NULL != data);
  assert(w > 0);
  assert(h > 0);

  std::fstream fh(file, std::fstream::out | std::fstream::binary);

  if (fh.bad()) {
    std::cerr << "__savePPM() : Opening file failed." << std::endl;
    return false;
  }

  if (channels == 1) {
    fh << "P5\n";
  } else if (channels == 3) {
    fh << "P6\n";
  } else {
    std::cerr << "__savePPM() : Invalid number of channels." << std::endl;
    return false;
  }

  fh << w << "\n" << h << "\n" << 0xff << std::endl;

  for (unsigned int i = 0; (i < (w * h * channels)) && fh.good(); ++i) {
    fh << data[i];
  }

  fh.flush();

  if (fh.bad()) {
    std::cerr << "__savePPM() : Writing data failed." << std::endl;
    return false;
  }

  fh.close();

  return true;
}
template <class T>
inline bool sdkLoadPGM(const char* file, T** data, unsigned int* w,
                       unsigned int* h) {
  unsigned char* idata = NULL;
  unsigned int channels;

  if (true != __loadPPM(file, &idata, w, h, &channels)) {
    return false;
  }

  unsigned int size = *w * *h * channels;

  // initialize mem if necessary
  // the correct size is checked / set in loadPGMc()
  if (NULL == *data) {
    *data = reinterpret_cast<T*>(malloc(sizeof(T) * size));
  }

  // copy and cast data
  std::transform(idata, idata + size, *data,
                 helper_image_internal::ConverterFromUByte<T>());

  free(idata);

  return true;
}

template <class T>
inline bool sdkLoadPPM4(const char* file, T** data, unsigned int* w,
                        unsigned int* h) {
  unsigned char* idata = 0;
  unsigned int channels;

  if (__loadPPM(file, &idata, w, h, &channels)) {
    // pad 4th component
    int size = *w * *h;
    // keep the original pointer
    unsigned char* idata_orig = idata;
    *data = reinterpret_cast<T*>(malloc(sizeof(T) * size * 4));
    unsigned char* ptr = *data;

    for (int i = 0; i < size; i++) {
      *ptr++ = *idata++;
      *ptr++ = *idata++;
      *ptr++ = *idata++;
      *ptr++ = 0;
    }

    free(idata_orig);
    return true;
  } else {
    free(idata);
    return false;
  }
}

template <class T>
inline bool sdkSavePGM(const char* file, T* data, unsigned int w,
                       unsigned int h) {
  unsigned int size = w * h;
  unsigned char* idata = (unsigned char*)malloc(sizeof(unsigned char) * size);

  std::transform(data, data + size, idata,
                 helper_image_internal::ConverterToUByte<T>());

  // write file
  bool result = __savePPM(file, idata, w, h, 1);

  // cleanup
  free(idata);

  return result;
}

bool sdkSavePPM4ub(const char* file, unsigned char* data, unsigned int w,
                   unsigned int h);

//////////////////////////////////////////////////////////////////////////////
//! Read file \filename and return the data
//! @return bool if reading the file succeeded, otherwise false
//! @param filename name of the source file
//! @param data  uninitialized pointer, returned initialized and pointing to
//!        the data read
//! @param len  number of data elements in data, -1 on error
//////////////////////////////////////////////////////////////////////////////
template <class T>
inline bool sdkReadFile(const char* filename, T** data, unsigned int* len,
                        bool verbose) {
  // check input arguments
  assert(NULL != filename);
  assert(NULL != len);

  // intermediate storage for the data read
  std::vector<T> data_read;

  // open file for reading
  FILE* fh = NULL;

  // check if filestream is valid
  if (FOPEN_FAIL(FOPEN(fh, filename, "r"))) {
    printf("Unable to open input file: %s\n", filename);
    return false;
  }

  // read all data elements
  T token;

  while (!feof(fh)) {
    fscanf(fh, "%f", &token);
    data_read.push_back(token);
  }

  // the last element is read twice
  data_read.pop_back();
  fclose(fh);

  // check if the given handle is already initialized
  if (NULL != *data) {
    if (*len != data_read.size()) {
      std::cerr << "sdkReadFile() : Initialized memory given but "
                << "size  mismatch with signal read "
                << "(data read / data init = " << (unsigned int)data_read.size()
                << " / " << *len << ")" << std::endl;

      return false;
    }
  } else {
    // allocate storage for the data read
    *data = reinterpret_cast<T*>(malloc(sizeof(T) * data_read.size()));
    // store signal size
    *len = static_cast<unsigned int>(data_read.size());
  }

  // copy data
  memcpy(*data, &data_read.front(), sizeof(T) * data_read.size());

  return true;
}

//////////////////////////////////////////////////////////////////////////////
//! Read file \filename and return the data
//! @return bool if reading the file succeeded, otherwise false
//! @param filename name of the source file
//! @param data  uninitialized pointer, returned initialized and pointing to
//!        the data read
//! @param len  number of data elements in data, -1 on error
//////////////////////////////////////////////////////////////////////////////
template <class T>
inline bool sdkReadFileBlocks(const char* filename, T** data, unsigned int* len,
                              unsigned int block_num, unsigned int block_size,
                              bool verbose) {
  // check input arguments
  assert(NULL != filename);
  assert(NULL != len);

  // open file for reading
  FILE* fh = fopen(filename, "rb");

  if (fh == NULL && verbose) {
    std::cerr << "sdkReadFile() : Opening file failed." << std::endl;
    return false;
  }

  // check if the given handle is already initialized
  // allocate storage for the data read
  data[block_num] = reinterpret_cast<T*>(malloc(block_size));

  // read all data elements
  fseek(fh, block_num * block_size, SEEK_SET);
  *len = fread(data[block_num], sizeof(T), block_size / sizeof(T), fh);

  fclose(fh);

  return true;
}

//////////////////////////////////////////////////////////////////////////////
//! Write a data file \filename
//! @return true if writing the file succeeded, otherwise false
//! @param filename name of the source file
//! @param data  data to write
//! @param len  number of data elements in data, -1 on error
//! @param epsilon  epsilon for comparison
//////////////////////////////////////////////////////////////////////////////
template <class T, class S>
inline bool sdkWriteFile(const char* filename, const T* data, unsigned int len,
                         const S epsilon, bool verbose, bool append = false) {
  assert(NULL != filename);
  assert(NULL != data);

  // open file for writing
  //    if (append) {
  std::fstream fh(filename, std::fstream::out | std::fstream::ate);

  if (verbose) {
    std::cerr << "sdkWriteFile() : Open file " << filename
              << " for write/append." << std::endl;
  }

  /*    } else {
          std::fstream fh(filename, std::fstream::out);
          if (verbose) {
              std::cerr << "sdkWriteFile() : Open file " << filename << " for
     write." << std::endl;
          }
      }
  */

  // check if filestream is valid
  if (!fh.good()) {
    if (verbose) {
      std::cerr << "sdkWriteFile() : Opening file failed." << std::endl;
    }

    return false;
  }

  // first write epsilon
  fh << "# " << epsilon << "\n";

  // write data
  for (unsigned int i = 0; (i < len) && (fh.good()); ++i) {
    fh << data[i] << ' ';
  }

  // Check if writing succeeded
  if (!fh.good()) {
    if (verbose) {
      std::cerr << "sdkWriteFile() : Writing file failed." << std::endl;
    }

    return false;
  }

  // file ends with nl
  fh << std::endl;

  return true;
}

//////////////////////////////////////////////////////////////////////////////
//! Compare two arrays of arbitrary type
//! @return  true if \a reference and \a data are identical, otherwise false
//! @param reference  timer_interface to the reference data / gold image
//! @param data       handle to the computed data
//! @param len        number of elements in reference and data
//! @param epsilon    epsilon to use for the comparison
//////////////////////////////////////////////////////////////////////////////
template <class T, class S>
inline bool compareData(const T* reference, const T* data,
                        const unsigned int len, const S epsilon,
                        const float threshold) {
  assert(epsilon >= 0);

  bool result = true;
  unsigned int error_count = 0;

  for (unsigned int i = 0; i < len; ++i) {
    float diff = static_cast<float>(reference[i]) - static_cast<float>(data[i]);
    bool comp = (diff <= epsilon) && (diff >= -epsilon);
    result &= comp;

    error_count += !comp;
  }

  if (threshold == 0.0f) {
    return (result) ? true : false;
  } else {
    if (error_count) {
      printf("%4.2f(%%) of bytes mismatched (count=%d)\n",
             static_cast<float>(error_count) * 100 / static_cast<float>(len),
             error_count);
    }

    return (len * threshold > error_count) ? true : false;
  }
}

//////////////////////////////////////////////////////////////////////////////
//! Compare two arrays of arbitrary type
//! @return  true if \a reference and \a data are identical, otherwise false
//! @param reference  handle to the reference data / gold image
//! @param data       handle to the computed data
//! @param len        number of elements in reference and data
//! @param epsilon    epsilon to use for the comparison
//! @param epsilon    threshold % of (# of bytes) for pass/fail
//////////////////////////////////////////////////////////////////////////////
template <class T, class S>
inline bool compareDataAsFloatThreshold(const T* reference, const T* data,
                                        const unsigned int len, const S epsilon,
                                        const float threshold) {
  assert(epsilon >= 0);

  constexpr float kMinEpisilonError = 1e-3f;
  // If we set epsilon to be 0, let's set a minimum threshold
  float max_error = std::max((float)epsilon, kMinEpisilonError);
  int error_count = 0;

  for (unsigned int i = 0; i < len; ++i) {
    float diff =
        fabs(static_cast<float>(reference[i]) - static_cast<float>(data[i]));
    bool comp = (diff < max_error);

    if (!comp) {
      error_count++;
    }
  }

  if (threshold == 0.0f) {
    if (error_count) {
      printf("total # of errors = %d\n", error_count);
    }

    return (error_count == 0) ? true : false;
  } else {
    if (error_count) {
      printf("%4.2f(%%) of bytes mismatched (count=%d)\n",
             static_cast<float>(error_count) * 100 / static_cast<float>(len),
             error_count);
    }

    return ((len * threshold > error_count) ? true : false);
  }
}

void sdkDumpBin(void* data, unsigned int bytes, const char* filename);

bool sdkCompareBin2BinUint(const char* src_file, const char* ref_file,
                           unsigned int nelements, const float epsilon,
                           const float threshold, char* exec_path);

bool sdkCompareBin2BinFloat(const char* src_file, const char* ref_file,
                            unsigned int nelements, float epsilon,
                            float threshold, char* exec_path);

bool sdkCompareL2fe(const float* reference, const float* data, unsigned int len,
                    float epsilon);

bool sdkLoadPPMub(const char* file, unsigned char** data, unsigned int* w,
                  unsigned int* h);

bool sdkLoadPPM4ub(const char* file, unsigned char** data, unsigned int* w,
                   unsigned int* h);

bool sdkComparePPM(const char* src_file, const char* ref_file, float epsilon,
                   float threshold, bool verboseErrors);

bool sdkComparePGM(const char* src_file, const char* ref_file, float epsilon,
                   float threshold, bool verboseErrors);
