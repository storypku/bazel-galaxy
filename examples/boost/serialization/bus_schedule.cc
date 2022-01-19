#include "examples/boost/serialization/bus_schedule.h"

#include <fstream>

#include "boost/archive/text_iarchive.hpp"
#include "boost/archive/text_oarchive.hpp"

std::ostream& operator<<(std::ostream& os, const GpsPosition& gp) {
  return os << ' ' << gp.degrees_ << (unsigned char)186 << gp.minutes_ << '\''
            << gp.seconds_ << '"';
}

std::ostream& operator<<(std::ostream& os, const BusStop& bs) {
  return os << bs.latitude_ << bs.longitude_ << ' ' << bs.Description();
}

std::ostream& operator<<(std::ostream& os, const BusRoute& br) {
  // note: we're displaying the pointer to permit verification
  // that duplicated pointers are properly restored.
  for (auto it = br.stops_.begin(); it != br.stops_.end(); ++it) {
    os << '\n' << std::hex << "0x" << *it << std::dec << ' ' << **it;
  }
  return os;
}

std::ostream& operator<<(std::ostream& os, const BusSchedule::TripInfo& ti) {
  return os << '\n' << ti.hour << ':' << ti.minute << ' ' << ti.driver << ' ';
}

std::ostream& operator<<(std::ostream& os, const BusSchedule& bs) {
  for (auto it = bs.schedule_.begin(); it != bs.schedule_.end(); ++it) {
    os << it->first << *(it->second);
  }
  return os;
}

absl::Status SaveSchedule(const BusSchedule& s, std::string_view filename) {
  // make an archive
  std::ofstream ofs(filename.data());
  if (!ofs) {
    return absl::UnavailableError(
        absl::StrCat("Failed to open ", filename, " for write."));
  }

  boost::archive::text_oarchive oa(ofs);
  oa << s;
  return absl::OkStatus();
}

absl::StatusOr<BusSchedule> RestoreSchedule(std::string_view filename) {
  // open the archive
  std::ifstream ifs(filename.data());
  if (!ifs) {
    return absl::NotFoundError(absl::StrCat("Failed to open", filename));
  }
  BusSchedule s;

  boost::archive::text_iarchive ia(ifs);
  // restore the schedule from the archive
  ia >> s;
  ifs.close();
  return s;
}
