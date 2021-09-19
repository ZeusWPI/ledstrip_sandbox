#include <iostream>
#include <sstream>
#include <vector>

#ifndef _LOG_
#define _LOG_

class Log {
public:
  Log() {}
  Log(unsigned int s) { size = s; }
  ~Log() {}
  template <typename T> Log &operator<<(const T &msg) {
    std::stringstream current_string;
    current_string << msg;
    os << msg;

    if (current_string.str().back() == '\n') {
      std::cout << "LOG: " << os.str();
      if (current >= size || full) {
        if (ctr >= size) {
          ctr = 0;
        }
        buffer[ctr] = os.str();
        full = true;
      } else {
        buffer.push_back(os.str());
      }
      ctr++;
      current++;
      os.str("");
    }
    return *this;
  }
  std::vector<std::string> getLogs() {
    std::vector<std::string> result;
    int iterator_limit = std::min(size, current);
    for (int i = iterator_limit - 1; i >= 0; i--) {
      result.emplace_back(buffer[(current - 1 - i) % size]);
    }
    return result;
  }

private:
  unsigned int current = 0;
  unsigned int ctr = 0;
  bool full = false;
  std::vector<std::string> buffer;
  std::stringstream os;
  unsigned int size = 255;
};

#endif