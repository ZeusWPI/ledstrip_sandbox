module script.lua.lua_script_instance;

import script.lua.lua_script_instance_task : LuaScriptInstanceTask;
import script.script_instance : ScriptInstance;

@safe:

final shared
class LuaScriptInstance : ScriptInstance
{
    this(string name, string sourceFileName, uint ledCount, bool autoStart)
    {
        super(name, sourceFileName, ledCount, autoStart);
    }

    override
    TaskEntrypoint taskEntrypoint()
        => &LuaScriptInstanceTask.entrypoint;
}
