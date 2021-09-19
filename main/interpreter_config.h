#include "log.h"
#include <string>

using namespace std;
struct InterpreterConfig {
  unsigned int begin;
  unsigned int length;
  bool enabled;
  std::string scriptkey; // To change the script in this part of the interpreter
                         // and get logger output
  std::string persistkey; // To persist the current running script to disk
  Log logger;
};