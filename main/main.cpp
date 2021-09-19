#include <cstdio>
#include <thread>
#include <chrono>
#include <cstring>
#include <cstdlib>
#include <csignal>
#include <unordered_map>
#include <atomic>
#include <optional>

#include "lua.hpp"
#include "ws2811.h"
#include "interpreter_config.h"
#include "log.h"
#include "json.hpp"

#include "httplib.h"

using json = nlohmann::json;
using std::chrono::duration_cast;
using std::chrono::milliseconds;
using std::chrono::system_clock;


#define TARGET_FREQ             WS2811_TARGET_FREQ
#define GPIO_PIN                18
#define DMA                     10
#define STRIP_TYPE              WS2812_STRIP		// WS2812/SK6812RGB integrated chip+leds
#define LED_COUNT               30*5

#define FPS                     15

int frametime = 1000 / FPS;

struct LedSegment {
  std::optional<std::thread> lua_thread;
  InterpreterConfig* interpreter_config;
  std::string owner;
  std::string lua_code;
};

std::vector<LedSegment*> ledsegments;

// this map is used to be able to see allowed leds from lua
std::unordered_map<lua_State*, InterpreterConfig*> statemap;
std::atomic<std::uint64_t> framecounter = {0};
ws2811_t ledstring =
{
    .freq = TARGET_FREQ,
    .dmanum = DMA,
    .channel =
    {
        [0] = {
            .gpionum = GPIO_PIN,
            .invert = 0,
            .count = LED_COUNT,
            .strip_type = STRIP_TYPE,
            .brightness = 10,
        },
        [1] = {
            .gpionum = 0,
            .invert = 0,
            .count = 0,
            .brightness = 0,
        },
    },
};
void hook(lua_State* L, lua_Debug *ar);

inline bool kill_thread_if_desired(lua_State *L) {
  if (!statemap[L]->enabled)
  {
      cout << "putting errors on the stack" << endl;
      lua_sethook(L, hook, LUA_MASKLINE, 0);
      luaL_error(L, "killed by manager");
      return true;
  }
  return false;
}

// TODO also call this hook about once every second
void hook(lua_State* L, lua_Debug *ar)
{
  kill_thread_if_desired(L);
}

extern "C" {
  static int c_override_print (lua_State *L) {
    kill_thread_if_desired(L);
    int n = lua_gettop(L);  /* number of arguments */
    int i;
    for (i = 1; i <= n; i++) {  /* for each argument */
      size_t l;
      const char *s = luaL_tolstring(L, i, &l);  /* convert it to string */
      if (i > 1)  /* not the first element? */
        statemap[L]->logger << '\t';  /* add a tab before it */
      statemap[L]->logger << s;  /* print it */
      lua_pop(L, 1);  /* pop result */
    }
    statemap[L]->logger << '\n';
    return 0;
  }

  static int c_led (lua_State *L) {
      kill_thread_if_desired(L);
      int virtual_location = luaL_checkinteger(L, 1);
      int red = luaL_checkinteger(L, 2);
  		int green = luaL_checkinteger(L, 3);
  		int blue = luaL_checkinteger(L, 4);
      InterpreterConfig* config = statemap[L];

      // Lua is one-based, let's keep it consistent and also make our API one-based
      if (virtual_location <= 0 || virtual_location > (int) config->length) {
        std::ostringstream errstream;
        errstream << "setting led " << virtual_location << " of strip with lenght " << config->length << "";
        luaL_argerror(L, 1, errstream.str().c_str());
        return 0;
      } else if (red < 0 || red > 0xff) {
        std::ostringstream errstream;
        errstream << "setting red channel to " << red << " but should be between 0 and 255";
        luaL_argerror(L, 2, errstream.str().c_str());
        return 0;
      } else if (green < 0 || green > 0xff) {
        std::ostringstream errstream;
        errstream << "setting green channel to " << green << " but should be between 0 and 255";
        luaL_argerror(L, 3, errstream.str().c_str());
        return 0;
      } else if (blue < 0 || blue > 0xff) {
        std::ostringstream errstream;
        errstream << "setting blue channel to " << blue << " but should be between 0 and 255";
        luaL_argerror(L, 4, errstream.str().c_str());
        return 0;
      }
      unsigned int real_location = config->begin + virtual_location - 1;
      // TODO remove this debugging line
      ledstring.channel[0].leds[real_location] = (red << 16) | (green << 8)| blue;
      return 0;
  }

  static int c_ledamount(lua_State *L) {
    kill_thread_if_desired(L);
    lua_pushinteger(L, statemap[L]->length);
    return 1;
  }

  static int c_delay(lua_State *L) {
    if (kill_thread_if_desired(L)) {return 0;}
    uint64_t millis = luaL_checkinteger (L, 1);
    uint64_t begin = duration_cast<milliseconds>(system_clock::now().time_since_epoch()).count();

    while (duration_cast<milliseconds>(system_clock::now().time_since_epoch()).count() - begin <  millis - 100) {
      std::this_thread::sleep_for(std::chrono::milliseconds(100-5));
      if (kill_thread_if_desired(L)) {return 0;}
    }
    uint64_t passed = (duration_cast<milliseconds>(system_clock::now().time_since_epoch()).count() - begin);
    std::this_thread::sleep_for(std::chrono::milliseconds(millis-passed));
    return 0;
  }

  static int c_waitframes(lua_State *L) {
    kill_thread_if_desired(L);
    int amount = luaL_checkinteger(L, 1);
    uint64_t destination = amount + framecounter;
    if (amount >= 2 * FPS) {
      std::this_thread::sleep_for(std::chrono::milliseconds(1000 * ((amount / FPS) - 1)));
    }
    while (framecounter <= destination) {
      std::this_thread::sleep_for(std::chrono::milliseconds(frametime / 2));
    }
    return 0;
  }
}

// Thanks to https://www.stefanmisik.com/post/sandboxing-lua-from-c.html
static void LuaLoadAndUndefine(lua_State* L, lua_CFunction openFunction, const char* moduleName, const char* functions[])
{
    /* Load the module, the module table gets placed on the top of the stack */
    luaL_requiref(L, moduleName, openFunction, 1);

    /* Undefine the unwanted functions */
    for (int i = 0; functions[i] != NULL; i++)
    {
        lua_pushnil(L);
        lua_setfield(L, -2, functions[i]);
    }

    /* Pop the module table */
    lua_pop(L, 1);
}

lua_State* setup_lua_sandbox(const char* luacode) {
  lua_State* L = luaL_newstate();
  L = luaL_newstate();
  if (!L) {
    return nullptr;
  }

  static const char* remove_base[] = {"assert",
    "collectgarbage", "dofile", "getmetatable", "loadfile", "load",
    "loadstring", "rawequal", "rawlen", "rawget", "rawset",
    "setmetatable", "print", NULL};
  LuaLoadAndUndefine(L, luaopen_base, "_G", remove_base);
  static const char* remove_str[] = {"dump", NULL};
  LuaLoadAndUndefine(L, luaopen_string, LUA_STRLIBNAME, remove_str);

  static const char* all_allowed[] = {NULL};
  LuaLoadAndUndefine(L, luaopen_table, LUA_TABLIBNAME, all_allowed);
  LuaLoadAndUndefine(L, luaopen_math, LUA_MATHLIBNAME, all_allowed);

	lua_pushcfunction(L, c_led);
  lua_setglobal(L, "led");
  lua_pushcfunction(L, c_ledamount);
  lua_setglobal(L, "ledamount");
  lua_pushcfunction(L, c_delay);
  lua_setglobal(L, "delay");
  lua_pushcfunction(L, c_waitframes);
  lua_setglobal(L, "waitframes");
  lua_pushcfunction(L, c_override_print);
  lua_setglobal(L, "print");

  luaL_loadbuffer(L, luacode, strlen(luacode), "script");
  lua_sethook(L, hook, LUA_MASKCOUNT, 1000);

  return L;
}

int execute_lua_sandbox(lua_State* L) {
  int ret = lua_pcall(L, 0, 0, 0);
  if (ret != 0) {
    statemap[L]->logger << "CRASH: " << lua_tostring(L, -1) << '\n';
    lua_close(L);
    return 1;
  }
  lua_close(L);
  return 0;
}

std::thread spawn_lua_tread(const char* luacode, InterpreterConfig* config) {
  lua_State* L = setup_lua_sandbox(luacode);
  statemap[L] = config;
  std::thread t(execute_lua_sandbox, L);
  return t;
}

void signal_callback_handler(int signum) {
  (void) signum;
  ws2811_fini(&ledstring);
  exit(1);
}

httplib::Server svr;

void starthttpserver() {
   svr.listen("0.0.0.0", 8080);
}



int main(int argc, char** argv)
{
  unsigned int amount = 10;
  unsigned int leds_per_segment = LED_COUNT / amount;
  for (unsigned int i = 0; i < amount; i++) {
    InterpreterConfig* config = new InterpreterConfig {
      .begin = leds_per_segment*i,
      .length = leds_per_segment,
      .enabled = true
    };
    cout << config->begin << endl;
    LedSegment* segment = new LedSegment {
      .lua_thread = std::nullopt,
      .interpreter_config = config,
      .owner = "",
      .lua_code = ""
    };
    ledsegments.push_back(segment);
  }

  svr.Get("/api/segments.json", [](const httplib::Request &, httplib::Response &res) {
    res.set_header("Access-Control-Allow-Origin", "*");
    res.set_header("Access-Control-Allow-Methods", "GET");
    json j;
    int i = 0;
    for (LedSegment* ledsegment : ledsegments) {
      json o;
      o["begin"] = ledsegment->interpreter_config->begin;
      o["length"] = ledsegment->interpreter_config->length;
      o["owner"] = ledsegment->owner;
      o["code"] = ledsegment->lua_code;
      o["id"] = i;
      i++;
      j.push_back(o);
    }
    res.set_content(j.dump(), "text/json");
  });

  svr.Put("/api/code.json", [](const httplib::Request &req, httplib::Response &res, const httplib::ContentReader &content_reader) {
    res.set_header("Access-Control-Allow-Origin", "*");
    res.set_header("Access-Control-Allow-Methods", "PUT");
    if (req.is_multipart_form_data()) {
      res.set_content("No multipart forms allowed", "text/plain");
      return true;
    } else {
      content_reader([&](const char *raw_data, size_t data_length) {
        std::string data(raw_data, data_length);
        auto j = json::parse(data);
        LedSegment* selected = ledsegments.at(j["id"].get<unsigned int>());
        if (selected->lua_thread.has_value()) {
          selected->interpreter_config->enabled = false;
          selected->lua_thread.value().join();
        }
        selected->owner = j["owner"].get<std::string>();
        selected->lua_code = j["code"].get<std::string>();
        selected->interpreter_config->enabled = true;
        selected->lua_thread = spawn_lua_tread(selected->lua_code.c_str(), selected->interpreter_config);
        cout << "Uploaded new code from " << selected->owner << " to segment " << j["id"].get<unsigned int>() << endl;
        return true;
      });
    }
    return true;
  });

  svr.Options("/api/code.json", [](const httplib::Request &req, httplib::Response &res) {
    res.set_header("Access-Control-Allow-Origin", "*");
    res.set_header("Access-Control-Allow-Methods", "PUT");
    return true;
  });

  std::thread httpserverthread(starthttpserver);

  ws2811_return_t ret;
  if ((ret = ws2811_init(&ledstring)) != WS2811_SUCCESS)
  {
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
