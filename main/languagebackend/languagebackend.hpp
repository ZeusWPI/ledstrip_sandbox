#pragma once
#include <atomic>


#include "messagecontainer.hpp"
#include "../language/language.hpp"

class LanguageBackend {

  std::atomic<bool> should_stop_var = {false};
  MessageContainer messagecontainer;

public:
  std::thread* languagethread = nullptr;
  // all function below
  // called from language implementation
  //

  virtual void log(std::string s) = 0;

  virtual bool set_led(int virtual_location, unsigned char red, unsigned char green, unsigned char blue) = 0;

  virtual int led_amount() = 0;

  virtual void delay(uint64_t milliseconds) = 0;

  virtual void wait_frames(int frames) = 0;

  std::optional<std::string> get_message(std::string topic) {
    return messagecontainer.get_message(topic);
  }

  void subscribe(std::string topic) {
    messagecontainer.subscribe(topic);
  }

  void unsubscribe(std::string topic) {
    messagecontainer.unsubscribe(topic);
  }

  bool should_stop() {
    return should_stop_var;
  }

  // all functions below
  // called from main controller/webserver
  //

  void stop() {
    // signal the language interpreter thread to stop
    // after that, you should call .join() on the interpreter
    should_stop_var = true;
  }

  void offer_message(std::string topic, std::string message) {
    messagecontainer.offer_message(topic, message);
  }

  virtual void reset() {
    messagecontainer.clear();
  }

  void start(Language* l) {
    this->languagethread = new std::thread([l]{l->run();});
  }
};