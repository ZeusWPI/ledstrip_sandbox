#pragma once

#include "../languagebackend/languagebackend.hpp"

class Language {

public:
  virtual void run() = 0;
  virtual std::string getCode() = 0;
  virtual std::string getLanguageID() = 0;
};