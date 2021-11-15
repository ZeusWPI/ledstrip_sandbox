#pragma once

#include "json.hpp"
using json = nlohmann::json;


class Config {
public:
  int ledamount = 600;
  std::vector<int> lengths;

  Config() {
    int segments = 10;
    for (int i = 0; i < segments; i++) {
      lengths.push_back(ledamount/segments);
    }
  }

  void from_json(json j) {
    if (j.contains("amount")) {
      this->ledamount = j["amount"].get<int>();
    }
    if (j.contains("segments")) {
      int current = 0;
      for (int i : j["segments"].get<std::vector<int>>()) {
        lengths.push_back(i);
        current += i;
      }
      if (current > this->ledamount) {
        throw std::overflow_error("segments added longer than total length");
      }
    }
  }
};