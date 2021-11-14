#pragma once

#include "../languagebackend/languagebackend.hpp"
#include "language.hpp"
#include "lua.hpp" // vendored lua

void hook(lua_State* L, lua_Debug *ar);

extern "C" {

static int c_getmessage(lua_State* L);

static int c_override_print(lua_State* L);

static int c_led(lua_State* L);

static int c_ledamount(lua_State* L);

static int c_delay(lua_State* L);

static int c_waitframes(lua_State* L);
}


class LuaLanguage : public Language {

private:

lua_State* L = nullptr;

// Thanks to https://www.stefanmisik.com/post/sandboxing-lua-from-c.html
static void LuaLoadAndUndefine(lua_State* L, lua_CFunction openFunction, const char *moduleName, const char *functions[]) {
  /* Load the module, the module table gets placed on the top of the stack */
  luaL_requiref(L, moduleName, openFunction, 1);

  /* Undefine the unwanted functions */
  for (int i = 0; functions[i] != NULL; i++) {
    lua_pushnil(L);
    lua_setfield(L, -2, functions[i]);
  }

  /* Pop the module table */
  lua_pop(L, 1);
}

lua_State* setup_lua_sandbox(const char *luacode) {
  L = luaL_newstate();
  if (!L) {
    return nullptr;
  }

  static const char *remove_base[] = {"assert",     "collectgarbage",
                                      "dofile",     "getmetatable",
                                      "loadfile",   "load",
                                      "loadstring", "rawequal",
                                      "rawlen",     "rawget",
                                      "rawset",     "setmetatable",
                                      "print",      NULL};
  LuaLoadAndUndefine(L, luaopen_base, "_G", remove_base);
  static const char *remove_str[] = {"dump", NULL};
  LuaLoadAndUndefine(L, luaopen_string, LUA_STRLIBNAME, remove_str);

  static const char *all_allowed[] = {NULL};
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
  lua_pushcfunction(L, c_getmessage);
  lua_setglobal(L, "getmessage");

  luaL_loadbuffer(L, luacode, strlen(luacode), "script");
  lua_sethook(L, hook, LUA_MASKCOUNT, 1000);

  return L;
}


public:
  // TODO if this crashes, add a mutex
  LanguageBackend* backend = nullptr;

  LuaLanguage() {
    // TODO remove this once I figure out how to
  }

  LuaLanguage(LanguageBackend* backend, std::string sourcecode) {
    this->backend = backend;
    this->L = this->setup_lua_sandbox(sourcecode.c_str());
  }

  void run() override {
    int ret = lua_pcall(L, 0, 0, 0);
    if (ret != 0) {
      // TODO get full stacktrace
      luaL_traceback(L, L, lua_tostring(L, -1), 1);
      std::string crashdump = "CRASH: ";
      crashdump.append(lua_tostring(L, -1));
      backend->log(crashdump);
    }
    lua_close(L);
  }
};

static std::map<lua_State*, LuaLanguage> lua_state_to_lualanguage_map;

inline bool kill_thread_if_desired(lua_State* L) {
  LanguageBackend* backend = lua_state_to_lualanguage_map[L].backend;
  if (backend->should_stop()) {
    cout << "putting errors on the stack" << endl;
    lua_sethook(L, hook, LUA_MASKLINE, 0);
    luaL_error(L, "killed");
    return true;
  }
  return false;
}

void hook(lua_State* L, lua_Debug *ar) { (void)ar;kill_thread_if_desired(L); }

extern "C" {

static int c_getmessage(lua_State* L) {
  kill_thread_if_desired(L);
  const char* c_topic = luaL_checkstring(L, 1);
  std::string topic(c_topic);
  LanguageBackend* backend = lua_state_to_lualanguage_map[L].backend;

  std::optional<std::string> element = backend->get_message(topic);
  if (element.has_value()) {
    const char* m = element.value().c_str();
    lua_pushlstring(L, m, strlen(m));
  } else {
    lua_pushnil(L);
  }
  return 1;
}

static int c_override_print(lua_State* L) {
  kill_thread_if_desired(L);
  // TODO implement this when swamp finishes the logger

  // int n = lua_gettop(L); /* number of arguments */
  // int i;
  // for (i = 1; i <= n; i++) { /* for each argument */
  //   size_t l;
  //   const char *s = luaL_tolstring(L, i, &l); /* convert it to string */
  //   if (i > 1)                                /* not the first element? */
  //     statemap[L]->logger << '\t';            /* add a tab before it */
  //   statemap[L]->logger << s;                 /* print it */
  //   lua_pop(L, 1);                            /* pop result */
  // }
  // statemap[L]->logger << '\n';
  return 0;
}

static int c_led(lua_State* L) {
  kill_thread_if_desired(L);
  int virtual_location = luaL_checkinteger(L, 1);
  int red = luaL_checkinteger(L, 2);
  int green = luaL_checkinteger(L, 3);
  int blue = luaL_checkinteger(L, 4);

  LanguageBackend* backend = lua_state_to_lualanguage_map[L].backend;
  // Lua is one-based, let's keep it consistent and also make our API one-based
  if (virtual_location <= 0 || virtual_location > (int)backend->led_amount()) {
    std::ostringstream errstream;
    errstream << "setting led " << virtual_location << " of strip with lenght "
              << backend->led_amount() << "";
    return luaL_argerror(L, 1, errstream.str().c_str());
  } else if (red < 0 || red > 0xff) {
    std::ostringstream errstream;
    errstream << "setting red channel to " << red
              << " but should be between 0 and 255";
    return luaL_argerror(L, 2, errstream.str().c_str());
  } else if (green < 0 || green > 0xff) {
    std::ostringstream errstream;
    errstream << "setting green channel to " << green
              << " but should be between 0 and 255";
    return luaL_argerror(L, 3, errstream.str().c_str());;
  } else if (blue < 0 || blue > 0xff) {
    std::ostringstream errstream;
    errstream << "setting blue channel to " << blue
              << " but should be between 0 and 255";
    return luaL_argerror(L, 4, errstream.str().c_str());;
  }
  backend->set_led(virtual_location - 1, red, green, blue);
  return 0;
}

static int c_ledamount(lua_State* L) {
  kill_thread_if_desired(L);
  LanguageBackend* backend = lua_state_to_lualanguage_map[L].backend;
  lua_pushinteger(L, backend->led_amount());
  return 1;
}

static int c_delay(lua_State* L) {
  kill_thread_if_desired(L);
  uint64_t millis = luaL_checkinteger(L, 1);
  LanguageBackend* backend = lua_state_to_lualanguage_map[L].backend;
  backend->delay(millis);
  kill_thread_if_desired(L);
  return 0;
}

// TODO maybe fix this by waiting for framecounter to change instead of sleeping
static int c_waitframes(lua_State* L) {
  kill_thread_if_desired(L);
  int amount = luaL_checkinteger(L, 1);
  LanguageBackend* backend = lua_state_to_lualanguage_map[L].backend;
  backend->wait_frames(amount);
  kill_thread_if_desired(L);
  return 0;
}
}