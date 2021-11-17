#pragma once

#include <iostream>
#include <sstream>
#include <vector>
#include <algorithm>

class Log {
private:
  unsigned int size = 1024;
  std::stringstream os;

  std::mutex buffer_guard; // guards all private variables below
  unsigned int num_strings_seen = 0;
  std::vector<std::string> buffer;

public:
  Log() {}
  Log(unsigned int s) { size = s; }
  ~Log() {}
  template <typename T> Log &operator<<(const T &msg) {
    std::stringstream current_string;
    current_string << msg;
    os << msg;

    if (current_string.str().back() == '\n') {
      std::lock_guard<std::mutex> lock(buffer_guard);
      std::cout << "LOG: " << os.str();
      if (num_strings_seen >= size) {
        buffer[num_strings_seen % size] = os.str();
      } else {
        buffer.push_back(os.str());
      }
      num_strings_seen++;
      os.str("");
    }
    return *this;
  }
  std::map<unsigned int, std::string> getLogs() {
    std::lock_guard<std::mutex> lock(buffer_guard);
    std::map<unsigned int, std::string> result;
    int begin = 0;
    if (num_strings_seen > size) {
      begin = num_strings_seen - size;
    }
    for (unsigned int i = begin; i < num_strings_seen; i++) {
      result[i] = buffer[i % size];
    }
    return result;
  }

  void clear() {
    buffer.clear();
  }
};
