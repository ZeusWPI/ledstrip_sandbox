#include <atomic>
#include <chrono>
#include <csignal>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <optional>
#include <thread>
#include <unordered_map>
#include <memory>
#include <filesystem>

#include "config.hpp"
#include "json.hpp"
#include "log.h"
#include "lua.hpp"
#include "ws2811.h"

#include "httplib.h"
#include "languagebackend/ledstriplanguagebackend.hpp"
#include "languagebackend/languagebackend.hpp"
#include "language/language.hpp"
#include "language/lualanguage.hpp"

using json = nlohmann::json;
using std::chrono::duration_cast;
using std::chrono::milliseconds;
using std::chrono::system_clock;

#define TARGET_FREQ WS2811_TARGET_FREQ
#define GPIO_PIN 18
#define DMA 10
#define STRIP_TYPE WS2812_STRIP // WS2812/SK6812RGB integrated chip+leds
#define LED_COUNT 690

#define FPS 15

int frametime = 1000 / FPS;

std::vector<LanguageBackend*> languagebackends;

std::atomic<std::uint64_t> framecounter {0};
ws2811_t ledstring = {
    .freq = TARGET_FREQ,
    .dmanum = DMA,
    .channel =
        {
            [0] =
                {
                    .gpionum = GPIO_PIN,
                    .invert = 0,
                    .count = LED_COUNT,
                    .strip_type = STRIP_TYPE,
                    .brightness = 255,
                },
            [1] =
                {
                    .gpionum = 0,
                    .invert = 0,
                    .count = 0,
                    .brightness = 0,
                },
        },
};

void signal_callback_handler(int signum) {
  (void)signum;
  ws2811_fini(&ledstring);
  exit(1);
}

httplib::Server svr;

void starthttpserver() { svr.listen("0.0.0.0", 8080); }

void startLanguage(unsigned int id, std::string code, std::string languageid, std::string owner) {
  std::cout << "owner=" << owner << " languageid=" << languageid << " id=" << id << std::endl;
  LanguageBackend* selected = languagebackends.at(id);
  if (selected->languagethread != nullptr) {
    std::cout << "there was still a language running, killing it" << std::endl;
    selected->stop();
    selected->languagethread->join();
  }
  selected->reset();
  Language* language;
  if (languageid == "lua") {
    language = new LuaLanguage(selected, code);
  } else {
    std::cout << "(!) languageid not found, not running code " << std::endl;
    return;
  }
  std::cout << "starting language..." << std::endl;
  selected->start(language);
  std::cout << "language started" << std::endl;
  selected->owner = owner;
  std::cout << "Uploaded new code from " << owner << " to segment " << id << std::endl;
}

int main(int argc, char **argv) {
  // read config and initialize led strips
  Config c;
  std::ifstream configfile("config.json");
  if (!configfile.fail()) {
    c.from_json(json::parse(configfile));
  }

  for(auto const& dir_entry: std::filesystem::directory_iterator{std::filesystem::path{"saved"}}) {
    if (dir_entry.is_regular_file()) {
      std::string segment_id = dir_entry.path().stem().string();
      if (std::all_of(segment_id.begin(), segment_id.end(), ::isdigit)) {
        std::string languageid = dir_entry.path().extension().string();
        int id = std::stoi(segment_id);
        std::ifstream saved_code_file(dir_entry.path());
        std::stringstream buffer;
        buffer << saved_code_file.rdbuf();
        startLanguage(id, buffer.str(), languageid, "SAVED");
      }
    }
  }

  svr.Get("/api/segments.json",
          [](const httplib::Request &, httplib::Response &res) {
            res.set_header("Access-Control-Allow-Origin", "*");
            res.set_header("Access-Control-Allow-Methods", "GET");
            json j;
            int i = 0;
            for (LanguageBackend *backend : languagebackends) {
              json o;
              o["begin"] = backend->begin;
              o["length"] = backend->length;
              o["owner"] = backend->owner;
              o["code"] = backend->currentcode;
              o["languageid"] = backend->languageid;
              o["id"] = i;
              i++;
              j.push_back(o);
            }
            res.set_content(j.dump(), "text/json");
          });

  svr.Put("/api/code.json", [](const httplib::Request &req,
                               httplib::Response &res,
                               const httplib::ContentReader &content_reader) {
    res.set_header("Access-Control-Allow-Origin", "*");
    res.set_header("Access-Control-Allow-Methods", "PUT");
    if (req.is_multipart_form_data()) {
      res.set_content("No multipart forms allowed", "text/plain");
      return true;
    } else {
      content_reader([&](const char *raw_data, size_t data_length) {
        std::string data(raw_data, data_length);
        auto j = json::parse(data);
        startLanguage(j["id"].get<unsigned int>(), j["code"].get<std::string>(), j["languageid"].get<std::string>(), j["owner"].get<std::string>());
        return true;
      });
    }
    return true;
  });

  svr.Options("/api/code.json",
              [](const httplib::Request &req, httplib::Response &res) {
                res.set_header("Access-Control-Allow-Origin", "*");
                res.set_header("Access-Control-Allow-Methods", "PUT");
                return true;
              });

  svr.Put("/api/mailbox.json", [](const httplib::Request &req,
                               httplib::Response &res,
                               const httplib::ContentReader &content_reader) {
    res.set_header("Access-Control-Allow-Origin", "*");
    res.set_header("Access-Control-Allow-Methods", "PUT");
    if (req.is_multipart_form_data()) {
      res.set_content("No multipart forms allowed", "text/plain");
      return true;
    } else {
      content_reader([&](const char *raw_data, size_t data_length) {
        std::string data(raw_data, data_length);
        auto j = json::parse(data);
        std::string topic = j["topic"].get<std::string>();
        std::string message = j["message"].get<std::string>();
        for (LanguageBackend* backend : languagebackends) {
          backend->offer_message(topic, message);
        }
        return true;
      });
    }
    return true;
  });

  std::thread httpserverthread(starthttpserver);

  ws2811_return_t ret;
  if ((ret = ws2811_init(&ledstring)) != WS2811_SUCCESS) {
    fprintf(stderr, "ws2811_init failed: %s\n", ws2811_get_return_t_str(ret));
    return ret;
  }
  signal(SIGINT, signal_callback_handler);
  signal(SIGHUP, signal_callback_handler);
  signal(SIGTERM, signal_callback_handler);

  ledstring.channel[0].leds[10] = 0x00200000;
  ledstring.channel[0].leds[11] = 0x00002000;
  ledstring.channel[0].leds[12] = 0x00000020;

  int start = 0;
  for (int length : c.lengths) {
    LanguageBackend* l = new LedstripLanguageBackend(ledstring, start, length);
    languagebackends.push_back(l);
    start += length;
  }

  std::cout << "starting render loop" << std::endl;
  while (true) {
    ws2811_render(&ledstring);
    framecounter++;
    std::this_thread::sleep_for(std::chrono::milliseconds(frametime));
  }
}
