#pragma once


#include <mutex>
#include <deque>
#include <memory>


class MessageContainer {
    std::map<std::string, std::deque<std::string>> map;
    std::mutex m;

public:

    MessageContainer() {}

    void subscribe(std::string topic) {
      std::lock_guard<std::mutex> lock(m);
      if (map.contains(topic)) return;
      map[topic] = {};
    }

    void unsubscribe(std::string topic) {
      std::lock_guard<std::mutex> lock(m);
      if (!map.contains(topic)) return;
      map.erase(topic);
    }

    std::optional<std::string> get_message(std::string topic) {
      std::lock_guard<std::mutex> lock(m);
      if (!map.contains(topic)) return std::nullopt;
      if (map[topic].empty()) {
        return std::nullopt;
      }
      std::string elem = map[topic].front();
      map[topic].pop_front();
      return { elem };
    }

    void offer_message(std::string topic, std::string message) {
      std::lock_guard<std::mutex> lock(m);
      if (!map.contains(topic)) return;
      map[topic].push_back(message);
    }

    void clear() {
      std::lock_guard<std::mutex> lock(m);
      map.clear();
    }
};