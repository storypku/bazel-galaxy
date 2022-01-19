#include <iostream>
#include <string>
#include <vector>

#include "absl/strings/str_format.h"
#include "absl/strings/str_join.h"
#include "examples/absl/time_it.h"

// How to run:
// GLOG_logtostderr=1 bazel run //examples/absl:hello_world
int main(int argc, char* argv[]) {
  google::InitGoogleLogging(argv[0]);

  std::vector<std::string> v = {"foo", "bar", "baz"};
  std::string s = absl::StrJoin(v, "-");

  std::cout << "Joined string: " << s << "\n";

  const int answer = 42;
  std::cout << absl::StreamFormat("The answer of universe is %d .", answer)
            << std::endl;
  TIME_IT(t1, "Walking to street");
  absl::SleepFor(absl::Milliseconds(500));
  return 0;
}
