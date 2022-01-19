#include "examples/boost/serialization/bus_schedule.h"

#include <fstream>

#include "boost/archive/text_iarchive.hpp"
#include "boost/archive/text_oarchive.hpp"
#include "gtest/gtest.h"

TEST(IntrusiveSerializationTest, TestGpsPosition) {
  std::ofstream ofs("gps.txt");
  // create class instance
  const GpsPosition g(35, 59, 24.567f);

  // save data to archive
  {
    boost::archive::text_oarchive oa(ofs);
    // write class instance to archive
    oa << g;
    // archive and stream closed when destructors are called
  }

  // ... some time later restore the class instance to its orginal state
  GpsPosition newg;
  {
    // create and open an archive for input
    std::ifstream ifs("gps.txt");
    boost::archive::text_iarchive ia(ifs);
    // read class state from archive
    ia >> newg;
    // archive and stream closed when destructors are called
  }
  EXPECT_EQ(g, newg);
}
