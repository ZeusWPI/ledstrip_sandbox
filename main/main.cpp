#include <cstdio>
#include <thread>
#include <chrono>
#include <cstring>
#include <cstdlib>
#include <csignal>
#include <unordered_map>
#include <atomic>

#include "lua.hpp"
#include "ws2811.h"
#include "interpreter_config.h"
#include "log.h"

#include "httplib.h"


#define TARGET_FREQ             WS2811_TARGET_FREQ
#define GPIO_PIN                18
#define DMA                     10
#define STRIP_TYPE              WS2811_STRIP_GBR		// WS2812/SK6812RGB integrated chip+leds
#define LED_COUNT               690

#define FPS                     15

int frametime = 1000 / FPS;

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
            .strip_type = WS2811_STRIP_GBR,
            .brightness = 255,
        },
        [1] = {
            .gpionum = 0,
            .invert = 0,
            .count = 0,
            .brightness = 0,
        },
    },
};

extern "C" {
  static int c_override_print (lua_State *L) {
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
      int virtual_location = luaL_checkinteger(L, 1);
      int red = luaL_checkinteger(L, 2);
  		int green = luaL_checkinteger(L, 3);
  		int blue = luaL_checkinteger(L, 4);
      InterpreterConfig* config = statemap[L];
      cerr << "Setting led " << virtual_location << " of strip with lenght " << config->length << "\n";

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
      printf("Setting led %d to %d %d %d\n", real_location, red, green, blue);
      ledstring.channel[0].leds[real_location] = (red << 16) | (green << 8)| blue;
      return 0;
  }

  static int c_ledamount(lua_State *L) {
    lua_pushinteger(L, statemap[L]->length);
    return 1;
  }

  static int c_delay(lua_State *L) {
    int millis = luaL_checkinteger (L, 1);
    std::this_thread::sleep_for(std::chrono::milliseconds(millis));
    return 0;
  }

  static int c_waitframes(lua_State *L) {
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
  InterpreterConfig* config = new InterpreterConfig {
    .begin = 0,
    .length = LED_COUNT,
    .enabled = true
  };



  svr.Get("/hi", [](const httplib::Request &, httplib::Response &res) {
    res.set_content("Hello World!", "text/plain");
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

  ledstring.channel[0].leds[0] = 0x0000ff00;
  std::thread t = spawn_lua_tread("while true do\nprint(\"begin\")\nled(2, 3, 4, 5)\ndelay(1000)\nled(1, 255, 128, 0)\ndelay(1000)\nprint(\"done\")\nend", config);

  while (true) {
    ws2811_render(&ledstring);
    std::this_thread::sleep_for(std::chrono::milliseconds(frametime));
  }
}