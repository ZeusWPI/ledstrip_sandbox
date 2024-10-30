module script.lua.lua_script;

import script.lua.lua_script_task : LuaScriptTask;
import script.script : Script;

@safe:

final shared
class LuaScript : Script
{
    this(string name, string fileName, uint ledCount, bool autoStart)
    {
        super(name, fileName, ledCount, autoStart);
    }

    override
    TaskEntrypoint taskEntrypoint()
        => &LuaScriptTask.entrypoint;
}
