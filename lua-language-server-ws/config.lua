return {
    Lua = {
        runtime = {
            version = "LuaJIT",
            builtin = {
                ["basic"]         = "enable",
                ["bit"]           = "enable",
                ["bit32"]         = "disable",
                ["builtin"]       = "enable",
                ["coroutine"]     = "disable",
                ["debug"]         = "disable",
                ["ffi"]           = "disable",
                ["io"]            = "disable",
                ["jit"]           = "disable",
                ["jit.profile"]   = "disable",
                ["jit.util"]      = "disable",
                ["math"]          = "enable",
                ["os"]            = "disable",
                ["package"]       = "disable",
                ["string"]        = "enable",
                ["string.buffer"] = "disable",
                ["table"]         = "enable",
                ["table.clear"]   = "disable",
                ["table.new"]     = "disable",
                ["utf8"]          = "disable"
            }
        }
    }
}