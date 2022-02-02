#include <iostream>

int main(int argc, char* argv[]) {
#if defined(GALAXY_COMPILER_CLANG)
  std::cout << "Hello world from clang compiler" << std::endl;
#else
  std::cout << "Hello world from gcc compiler" << std::endl;
#endif
}
