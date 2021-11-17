#pragma once

#include <chrono>

#include "./languagebackend.hpp"


using std::chrono::duration_cast;
using std::chrono::milliseconds;
using std::chrono::system_clock;

class LedstripLanguageBackend : public LanguageBackend {

  ws2811_t ledstring;
  int frametime;
  std::atomic<uint64_t> *framecounter;

public:
  // all function below
  // called from language implementation
  //
  LedstripLanguageBackend(ws2811_t ledstring, int ft, std::atomic<uint64_t> *fc, int begin, int length) : LanguageBackend(begin, length) {
    this->ledstring = ledstring;
    this->frametime = ft;
    this->framecounter = fc;
  }

  bool set_led(int virtual_location, uint8_t red, uint8_t green, uint8_t blue) override {
    if (virtual_location < 0 || virtual_location >= this->length) {
      std::cout << "virtual " << virtual_location << "out of range on strip with length " << this->length << std::endl;
      std::cout << "this should have been caught in the language implementation" << std::endl;
      return false;
    }
    int real_location = begin + virtual_location;
    this->ledstring.channel[0].leds[real_location] = (((uint32_t)red) << 16) | (((uint32_t)green) << 8) | (uint32_t)blue;
    return true;
  }

  int led_amount() override {
    return this->length;
  }

  void delay(uint64_t millis) override {
    if (this->should_stop()) {
      return;
    }
    uint64_t begin = duration_cast<milliseconds>(system_clock::now().time_since_epoch()).count();

    while (duration_cast<milliseconds>(system_clock::now().time_since_epoch()).count() - begin < millis - 100) {
      std::this_thread::sleep_for(std::chrono::milliseconds(100 - 5));
      if (this->should_stop()) {
        return;
      }
    }
    uint64_t passed = duration_cast<milliseconds>(system_clock::now().time_since_epoch()).count() - begin;
    if (millis > passed) {
      std::this_thread::sleep_for(std::chrono::milliseconds(millis - passed));
    }
    return;
  }

  void wait_frames(int frames) override {
    std::uint64_t start = this->framecounter->load();

    while (start + frames > this->framecounter->load()) {
      std::this_thread::sleep_for(std::chrono::milliseconds((this->frametime)/2));
      if (this->should_stop()) {
        return;
      }
    }

    return;
  };

  void reset() override {
    LanguageBackend::reset();
    std::cout << "resetting ledstrip from " << this->begin << " with lenght " << this->length << std::endl;
    for (int i = 0; i < this->length; i++) {
      this->ledstring.channel[0].leds[this->begin + i] = 0;
    }
  }
};
