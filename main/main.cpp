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

#include "interpreter_config.h"
#include "json.hpp"
#include "safequeue.hpp"
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

struct LedSegment {
  std::optional<std::thread> lua_thread;
  InterpreterConfig *interpreter_config;
  std::string owner;
  std::string lua_code;
  SafeQueue<std::string> mailbox;
};

std::vector<LanguageBackend*> languagebackends;

std::atomic<std::uint64_t> framecounter = {0};
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

int main(int argc, char **argv) {
  unsigned int amount = 10;
  unsigned int leds_per_segment = LED_COUNT / amount;
  for (unsigned int i = 0; i < amount; i++) {
    LanguageBackend* l = new LedstripLanguageBackend(ledstring, leds_per_segment * i, leds_per_segment);
    languagebackends.push_back(l);
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
        LanguageBackend* selected = languagebackends.at(j["id"].get<unsigned int>());
        if (selected->languagethread != nullptr) {
          selected->stop();
          selected->languagethread->join();
        }
        selected->reset();
        Language* language = new LuaLanguage(selected, j["code"].get<std::string>());
        selected->start(language);
        selected->owner = j["owner"].get<std::string>();
        cout << "Uploaded new code from " << j["owner"].get<std::string>() << " to segment "
             << j["id"].get<unsigned int>() << endl;
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

  while (true) {
    ws2811_render(&ledstring);
    std::this_thread::sleep_for(std::chrono::milliseconds(frametime));
  }
}
