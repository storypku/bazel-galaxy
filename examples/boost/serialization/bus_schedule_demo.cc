#include "examples/boost/serialization/bus_schedule.h"

int main(int argc, char* argv[]) {
  // make the schedule
  BusSchedule original_schedule;

  // fill in the data
  // make a few stops
  BusStop* bs0 = new BusStopCorner(GpsPosition(34, 135, 52.560f),
                                   GpsPosition(134, 22, 78.30f), "24th Street",
                                   "10th Avenue");
  BusStop* bs1 = new BusStopCorner(GpsPosition(35, 137, 23.456f),
                                   GpsPosition(133, 35, 54.12f), "State street",
                                   "Cathedral Vista Lane");
  BusStop* bs2 =
      new BusStopDestination(GpsPosition(35, 136, 15.456f),
                             GpsPosition(133, 32, 15.300f), "White House");
  BusStop* bs3 =
      new BusStopDestination(GpsPosition(35, 134, 48.789f),
                             GpsPosition(133, 32, 16.230f), "Lincoln Memorial");

  // make a  routes
  BusRoute route0;
  route0.Append(bs0);
  route0.Append(bs1);
  route0.Append(bs2);

  // add trips to schedule
  original_schedule.Append("bob", 6, 24, &route0);
  original_schedule.Append("bob", 9, 57, &route0);
  original_schedule.Append("alice", 11, 02, &route0);

  // make aother routes
  BusRoute route1;
  route1.Append(bs3);
  route1.Append(bs2);
  route1.Append(bs1);

  // add trips to schedule
  original_schedule.Append("ted", 7, 17, &route1);
  original_schedule.Append("ted", 9, 38, &route1);
  original_schedule.Append("alice", 11, 47, &route1);

  // display the complete schedule
  std::cout << "original schedule: " << std::endl;
  std::cout << original_schedule << std::endl;

  std::string filename("demo_file.txt");
  // save the schedule
  if (const auto status = SaveSchedule(original_schedule, filename);
      !status.ok()) {
    std::cerr << "Failed to SaveSchedule: " << status << std::endl;
    return -1;
  }

  delete bs0;
  delete bs1;
  delete bs2;
  delete bs3;

  auto new_schedule = RestoreSchedule(filename);
  if (!new_schedule.ok()) {
    std::cerr << "Failed to RestoreSchedule from " << filename << ": "
              << new_schedule.status() << std::endl;
    return -1;
  }

  // and display
  std::cout << "Restored schedule: " << std::endl;
  std::cout << *new_schedule << std::endl;
  // should be the same as the old one. (except for the pointer values)
  return 0;
}
