#pragma once
#include <atomic>


#include "messagecontainer.hpp"
#include "../language/language.hpp"
#include "log.h"

class LanguageBackend {

  std::atomic<bool> should_stop_var {false};
  MessageContainer messagecontainer;

public:
  std::thread* languagethread = nullptr;
  std::string owner = "";
  std::string currentcode = "";
  std::string languageid = "";
  int begin;
  int length;
  Log logger;

  LanguageBackend(int begin, int length) {
    this->begin = begin;
    this->length = length;
  }

  // all function below
  // called from language implementation
  //

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
    return this->should_stop_var.load();
  }

  // all functions below
  // called from main controller/webserver
  //

  void stop() {
    // signal the language interpreter thread to stop
    // after that, you should call .join() on the interpreter
    this->should_stop_var.store(true);
  }

  void offer_message(std::string topic, std::string message) {
    messagecontainer.offer_message(topic, message);
  }

  virtual void reset() {
    messagecontainer.clear();
    this->should_stop_var.store(false);
  }

  void start(Language* l) {
    this->languageid = l->getLanguageID();
    this->currentcode = l->getCode();
    this->languagethread = new std::thread([l]{l->run();});
  }

  std::map<unsigned int, std::string> get_logs() {
    return this->logger.getLogs();
  }
};
