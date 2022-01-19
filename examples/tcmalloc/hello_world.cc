#include <cstddef>
#include <iostream>

int main() {
  std::cout << "Standard Alignment: " << alignof(std::max_align_t) << '\n';

  double* ptr = (double*)malloc(sizeof(double));
  std::cout << "Double Alignment: " << alignof(*ptr) << '\n';
  free(ptr);

  char* ptr2 = (char*)malloc(1);
  std::cout << "Char Alignment: " << alignof(*ptr2) << '\n';
  free(ptr2);

  void* ptr3 = nullptr;
  std::cout << "Sizeof void*: " << sizeof(ptr3) << '\n';
  return 0;
}
