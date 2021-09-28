#include <mutex>
#include <deque>
#include <memory>


template<class T>
class SafeQueue {
    std::deque<std::shared_ptr<T>> q;
    std::mutex m;

public:

    SafeQueue() {}

    void push(std::shared_ptr<T> elem) {
      if (elem == nullptr) {
        return;
      }
      std::lock_guard<std::mutex> lock(m);
      q.push_back(elem);
    }

    std::shared_ptr<T> pop_front() {
      std::lock_guard<std::mutex> lock(m);
      if (q.empty()) {
          return nullptr;
      }
      std::shared_ptr<T> elem = q.front();
      q.pop_front();
      return elem;
    }

    void clear() {
      std::lock_guard<std::mutex> lock(m);
      q.clear();
    }
};