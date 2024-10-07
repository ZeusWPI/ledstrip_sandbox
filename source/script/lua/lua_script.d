module script.lua.lua_script;

import script.lua.internal.lua_script_task : LuaScriptTask;
import script.script : Script;

import core.time : Duration;

import vibe.core.log;
import vibe.core.task : Task;
import vibe.core.taskpool : TaskPool;

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
