#include <iostream>
#include <string>
#include <vector>

#include "absl/strings/str_format.h"
#include "absl/strings/str_join.h"

int main() {
  std::vector<std::string> v = {"foo", "bar", "baz"};
  std::string s = absl::StrJoin(v, "-");

  std::cout << "Joined string: " << s << "\n";

  const int answer = 42;
  std::cout << absl::StreamFormat("The answer of universe is %d .", answer)
            << std::endl;
  return 0;
}
