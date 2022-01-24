#include "examples/cuda/common/image_helper.h"

bool sdkSavePPM4ub(const char* file, unsigned char* data, unsigned int w,
                   unsigned int h) {
  // strip 4th component
  int size = w * h;
  unsigned char* ndata =
      (unsigned char*)malloc(sizeof(unsigned char) * size * 3);
  unsigned char* ptr = ndata;

  for (int i = 0; i < size; i++) {
    *ptr++ = *data++;
    *ptr++ = *data++;
    *ptr++ = *data++;
    data++;
  }

  bool result = __savePPM(file, ndata, w, h, 3);
  free(ndata);
  return result;
}

void sdkDumpBin(void* data, unsigned int bytes, const char* filename) {
  printf("sdkDumpBin: <%s>\n", filename);
  FILE* fp;
  FOPEN(fp, filename, "wb");
  fwrite(data, bytes, 1, fp);
  fflush(fp);
  fclose(fp);
}

bool sdkCompareBin2BinUint(const char* src_file, const char* ref_file,
                           unsigned int nelements, const float epsilon,
                           const float threshold, char* exec_path) {
  unsigned int *src_buffer, *ref_buffer;
  FILE *src_fp = NULL, *ref_fp = NULL;

  uint64_t error_count = 0;
  size_t fsize = 0;

  if (FOPEN_FAIL(FOPEN(src_fp, src_file, "rb"))) {
    printf("compareBin2Bin <unsigned int> unable to open src_file: %s\n",
           src_file);
    error_count++;
  }

  if (FOPEN_FAIL(FOPEN(ref_fp, ref_file, "rb"))) {
    printf(
        "compareBin2Bin <unsigned int>"
        " unable to open ref_file: %s\n",
        ref_file);
    error_count++;
  }

  if (src_fp && ref_fp) {
    src_buffer = (unsigned int*)malloc(nelements * sizeof(unsigned int));
    ref_buffer = (unsigned int*)malloc(nelements * sizeof(unsigned int));

    fsize = fread(src_buffer, nelements, sizeof(unsigned int), src_fp);
    fsize = fread(ref_buffer, nelements, sizeof(unsigned int), ref_fp);

    printf(
        "> compareBin2Bin <unsigned int> nelements=%d,"
        " epsilon=%4.2f, threshold=%4.2f\n",
        nelements, epsilon, threshold);
    printf("   src_file <%s>, size=%d bytes\n", src_file,
           static_cast<int>(fsize));
    printf("   ref_file <%s>, size=%d bytes\n", ref_file,
           static_cast<int>(fsize));

    if (!compareData<unsigned int, float>(ref_buffer, src_buffer, nelements,
                                          epsilon, threshold)) {
      error_count++;
    }

    fclose(src_fp);
    fclose(ref_fp);

    free(src_buffer);
    free(ref_buffer);
  } else {
    if (src_fp) {
      fclose(src_fp);
    }

    if (ref_fp) {
      fclose(ref_fp);
    }
  }

  if (error_count == 0) {
    printf("  OK\n");
  } else {
    printf("  FAILURE: %d errors...\n", (unsigned int)error_count);
  }

  return (error_count == 0);  // returns true if all pixels pass
}

bool sdkCompareBin2BinFloat(const char* src_file, const char* ref_file,
                            unsigned int nelements, const float epsilon,
                            const float threshold, char* exec_path) {
  float *src_buffer = NULL, *ref_buffer = NULL;
  FILE *src_fp = NULL, *ref_fp = NULL;
  size_t fsize = 0;

  uint64_t error_count = 0;

  if (FOPEN_FAIL(FOPEN(src_fp, src_file, "rb"))) {
    printf("compareBin2Bin <float> unable to open src_file: %s\n", src_file);
    error_count = 1;
  }

  if (FOPEN_FAIL(FOPEN(ref_fp, ref_file, "rb"))) {
    printf("compareBin2Bin <float> unable to open ref_file: %s\n", ref_file);
    error_count = 1;
  }

  if (src_fp && ref_fp) {
    src_buffer = reinterpret_cast<float*>(malloc(nelements * sizeof(float)));
    ref_buffer = reinterpret_cast<float*>(malloc(nelements * sizeof(float)));

    printf(
        "> compareBin2Bin <float> nelements=%d, epsilon=%4.2f,"
        " threshold=%4.2f\n",
        nelements, epsilon, threshold);
    fsize = fread(src_buffer, sizeof(float), nelements, src_fp);
    printf("   src_file <%s>, size=%d bytes\n", src_file,
           static_cast<int>(fsize * sizeof(float)));
    fsize = fread(ref_buffer, sizeof(float), nelements, ref_fp);
    printf("   ref_file <%s>, size=%d bytes\n", ref_file,
           static_cast<int>(fsize * sizeof(float)));

    if (!compareDataAsFloatThreshold<float, float>(
            ref_buffer, src_buffer, nelements, epsilon, threshold)) {
      error_count++;
    }

    fclose(src_fp);
    fclose(ref_fp);

    free(src_buffer);
    free(ref_buffer);
  } else {
    if (src_fp) {
      fclose(src_fp);
    }

    if (ref_fp) {
      fclose(ref_fp);
    }
  }

  if (error_count == 0) {
    printf("  OK\n");
  } else {
    printf("  FAILURE: %d errors...\n", (unsigned int)error_count);
  }

  return (error_count == 0);  // returns true if all pixels pass
}

bool sdkCompareL2fe(const float* reference, const float* data,
                    const unsigned int len, const float epsilon) {
  assert(epsilon >= 0);

  float error = 0;
  float ref = 0;

  for (unsigned int i = 0; i < len; ++i) {
    float diff = reference[i] - data[i];
    error += diff * diff;
    ref += reference[i] * reference[i];
  }

  float normRef = sqrtf(ref);

  if (fabs(ref) < 1e-7) {
    return false;
  }

  float normError = sqrtf(error);
  error = normError / normRef;
  return error < epsilon;
}

bool sdkLoadPPMub(const char* file, unsigned char** data, unsigned int* w,
                  unsigned int* h) {
  unsigned int channels;
  return __loadPPM(file, data, w, h, &channels);
}

bool sdkLoadPPM4ub(const char* file, unsigned char** data, unsigned int* w,
                   unsigned int* h) {
  unsigned char* idata = 0;
  unsigned int channels;

  if (__loadPPM(file, &idata, w, h, &channels)) {
    // pad 4th component
    int size = *w * *h;
    // keep the original pointer
    unsigned char* idata_orig = idata;
    *data = (unsigned char*)malloc(sizeof(unsigned char) * size * 4);
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

bool sdkComparePPM(const char* src_file, const char* ref_file,
                   const float epsilon, const float threshold,
                   bool verboseErrors) {
  unsigned char *src_data, *ref_data;
  uint64_t error_count = 0;
  unsigned int ref_width, ref_height;
  unsigned int src_width, src_height;

  if (src_file == NULL || ref_file == NULL) {
    if (verboseErrors) {
      std::cerr << "PPMvsPPM: src_file or ref_file is NULL."
                   "  Aborting comparison\n";
    }

    return false;
  }

  if (verboseErrors) {
    std::cerr << "> Compare (a)rendered:  <" << src_file << ">\n";
    std::cerr << ">         (b)reference: <" << ref_file << ">\n";
  }

  if (sdkLoadPPM4ub(ref_file, &ref_data, &ref_width, &ref_height) != true) {
    if (verboseErrors) {
      std::cerr << "PPMvsPPM: unable to load ref image file: " << ref_file
                << "\n";
    }

    return false;
  }

  if (sdkLoadPPM4ub(src_file, &src_data, &src_width, &src_height) != true) {
    std::cerr << "PPMvsPPM: unable to load src image file: " << src_file
              << "\n";
    return false;
  }

  if (src_height != ref_height || src_width != ref_width) {
    if (verboseErrors) {
      std::cerr << "PPMvsPPM: source and ref size mismatch (" << src_width
                << "," << src_height << ")vs(" << ref_width << "," << ref_height
                << ")\n";
    }
  }

  if (verboseErrors) {
    std::cerr << "PPMvsPPM: comparing images size (" << src_width << ","
              << src_height << ") epsilon(" << epsilon << "), threshold("
              << threshold * 100 << "%)\n";
  }

  if (compareData(ref_data, src_data, src_width * src_height * 4, epsilon,
                  threshold) == false) {
    error_count = 1;
  }

  if (error_count == 0) {
    if (verboseErrors) {
      std::cerr << "    OK\n\n";
    }
  } else {
    if (verboseErrors) {
      std::cerr << "    FAILURE!  " << error_count << " errors...\n\n";
    }
  }

  // returns true if all pixels pass
  return (error_count == 0) ? true : false;
}

bool sdkComparePGM(const char* src_file, const char* ref_file,
                   const float epsilon, const float threshold,
                   bool verboseErrors) {
  unsigned char *src_data = 0, *ref_data = 0;
  uint64_t error_count = 0;
  unsigned int ref_width, ref_height;
  unsigned int src_width, src_height;

  if (src_file == NULL || ref_file == NULL) {
    if (verboseErrors) {
      std::cerr << "PGMvsPGM: src_file or ref_file is NULL."
                   "  Aborting comparison\n";
    }

    return false;
  }

  if (verboseErrors) {
    std::cerr << "> Compare (a)rendered:  <" << src_file << ">\n";
    std::cerr << ">         (b)reference: <" << ref_file << ">\n";
  }

  if (sdkLoadPPMub(ref_file, &ref_data, &ref_width, &ref_height) != true) {
    if (verboseErrors) {
      std::cerr << "PGMvsPGM: unable to load ref image file: " << ref_file
                << "\n";
    }

    return false;
  }

  if (sdkLoadPPMub(src_file, &src_data, &src_width, &src_height) != true) {
    std::cerr << "PGMvsPGM: unable to load src image file: " << src_file
              << "\n";
    return false;
  }

  if (src_height != ref_height || src_width != ref_width) {
    if (verboseErrors) {
      std::cerr << "PGMvsPGM: source and ref size mismatch (" << src_width
                << "," << src_height << ")vs(" << ref_width << "," << ref_height
                << ")\n";
    }
  }

  if (verboseErrors)
    std::cerr << "PGMvsPGM: comparing images size (" << src_width << ","
              << src_height << ") epsilon(" << epsilon << "), threshold("
              << threshold * 100 << "%)\n";

  if (compareData(ref_data, src_data, src_width * src_height, epsilon,
                  threshold) == false) {
    error_count = 1;
  }

  if (error_count == 0) {
    if (verboseErrors) {
      std::cerr << "    OK\n\n";
    }
  } else {
    if (verboseErrors) {
      std::cerr << "    FAILURE!  " << error_count << " errors...\n\n";
    }
  }

  // returns true if all pixels pass
  return (error_count == 0) ? true : false;
}
