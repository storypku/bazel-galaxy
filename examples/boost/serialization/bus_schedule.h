#pragma once

#include <cmath>
#include <iostream>
#include <limits>
#include <list>
#include <string>
#include <string_view>

#include "absl/status/statusor.h"
#include "absl/strings/str_cat.h"
#include "boost/serialization/assume_abstract.hpp"
#include "boost/serialization/base_object.hpp"
#include "boost/serialization/list.hpp"
#include "boost/serialization/string.hpp"
#include "boost/serialization/utility.hpp"

class GpsPosition {
 public:
  // every serializable class needs a constructor
  GpsPosition() = default;
  GpsPosition(int d, int m, float s) : degrees_(d), minutes_(m), seconds_(s) {}

 public:
  bool operator==(const GpsPosition& rhs) const {
    return this->degrees_ == rhs.degrees_ && this->minutes_ == rhs.minutes_ &&
           std::abs(this->seconds_ - rhs.seconds_) <
               std::numeric_limits<float>::epsilon();
  }

  bool operator!=(const GpsPosition& rhs) const { return *this == rhs; }

 private:
  int degrees_;
  int minutes_;
  float seconds_;

 private:
  friend std::ostream& operator<<(std::ostream& os, const GpsPosition& gp);
  friend class boost::serialization::access;
  template <class Archive>
  void serialize(Archive& ar, const unsigned int /* fileversion */) {
    ar& degrees_& minutes_& seconds_;
  }
};

class BusStop {
 public:
  BusStop() = default;
  virtual ~BusStop() = default;

 protected:
  BusStop(const GpsPosition& lat, const GpsPosition& lon)
      : latitude_(lat), longitude_(lon) {}
  virtual std::string Description() const = 0;

 private:
  GpsPosition latitude_;
  GpsPosition longitude_;
  template <class Archive>
  void serialize(Archive& ar, const unsigned int version) {
    ar& latitude_;
    ar& longitude_;
  }

  friend class boost::serialization::access;
  friend std::ostream& operator<<(std::ostream& os, const BusStop& gp);
};

BOOST_SERIALIZATION_ASSUME_ABSTRACT(BusStop)

class BusStopCorner : public BusStop {
 private:
  friend class boost::serialization::access;
  std::string street1_;
  std::string street2_;

  template <class Archive>
  void serialize(Archive& ar, const unsigned int version) {
    // save/load base class information
    ar& boost::serialization::base_object<BusStop>(*this);
    ar& street1_& street2_;
  }

 public:
  BusStopCorner() = default;
  BusStopCorner(const GpsPosition& lat, const GpsPosition& lon,
                const std::string& s1, const std::string& s2)
      : BusStop(lat, lon), street1_(s1), street2_(s2) {}

  virtual std::string Description() const {
    return absl::StrCat(street1_, " and ", street2_);
  }
};

class BusStopDestination : public BusStop {
 private:
  friend class boost::serialization::access;
  std::string name_;
  template <class Archive>
  void serialize(Archive& ar, const unsigned int version) {
    ar& boost::serialization::base_object<BusStop>(*this) & name_;
  }

 public:
  BusStopDestination() = default;
  BusStopDestination(const GpsPosition& lat, const GpsPosition& lon,
                     const std::string& name)
      : BusStop(lat, lon), name_(name) {}
  virtual std::string Description() const { return name_; }
};

class BusRoute {
 public:
  BusRoute() = default;
  void Append(BusStop* bs) { stops_.push_back(bs); }

 private:
  friend class boost::serialization::access;
  friend std::ostream& operator<<(std::ostream& os, const BusRoute& br);

 private:
  std::list<BusStop*> stops_;
  template <class Archive>
  void serialize(Archive& ar, const unsigned int version) {
    // in this program, these classes are never serialized directly but rather
    // through a pointer to the base class BusStop. So we need a way to be
    // sure that the archive contains information about these derived classes.
    // ar.template register_type<BusStopCorner>();
    ar.register_type(static_cast<BusStopCorner*>(nullptr));
    // ar.template register_type<BusStopDestination>();
    ar.register_type(static_cast<BusStopDestination*>(nullptr));
    // serialization of stl collections is already defined
    // in the header
    ar& stops_;
  }
};

// illustrates nesting of serializable classes
//
// illustrates use of version number to automatically grandfather older
// versions of the same class.

class BusSchedule {
 private:
  // note: this structure was made public. because the friend declarations
  // didn't seem to work as expected.
  struct TripInfo {
    template <class Archive>
    void serialize(Archive& ar, const unsigned int file_version) {
      // in versions 2 or later
      if (file_version >= 2) {
        // read the drivers name
        ar& driver;
      }
      // all versions have the follwing info
      ar& hour& minute;
    }

    // starting time
    int hour;
    int minute;
    // only after system shipped was the driver's name added to the class
    std::string driver;
    TripInfo() = default;
    TripInfo(int h, int m, const std::string& d)
        : hour(h), minute(m), driver(d) {}
  };

 public:
  BusSchedule() = default;
  void Append(const std::string& d, int h, int m, BusRoute* br) {
    schedule_.emplace_back(std::make_pair(TripInfo(h, m, d), br));
  }

 private:
  friend class boost::serialization::access;
  friend std::ostream& operator<<(std::ostream& os, const BusSchedule& bs);
  friend std::ostream& operator<<(std::ostream& os,
                                  const BusSchedule::TripInfo& ti);

 private:
  std::list<std::pair<TripInfo, BusRoute*> > schedule_;
  template <class Archive>
  void serialize(Archive& ar, const unsigned int version) {
    ar& schedule_;
  }
};

BOOST_CLASS_VERSION(BusSchedule::TripInfo, 2)

absl::Status SaveSchedule(const BusSchedule& s, std::string_view filename);
absl::StatusOr<BusSchedule> RestoreSchedule(std::string_view filename);
