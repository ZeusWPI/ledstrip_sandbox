module script.lua.lua_script_instance;

import script.lua.lua_script_instance_thread : LuaScriptInstanceThread;
import script.script_instance : ScriptExtension, ScriptInstance;

@safe:

final shared
class LuaScriptInstance : ScriptInstance
{
    this(string name, string sourceFileName, uint ledCount, bool autoStart)
    {
        super(name, sourceFileName, ledCount, autoStart);
    }

scope:
    override
    ThreadEntrypoint threadEntrypoint()
        => &LuaScriptInstanceThread.entrypoint;

    override pure nothrow @nogc
    ScriptExtension extension() const
        => ScriptExtension.lua;
}
