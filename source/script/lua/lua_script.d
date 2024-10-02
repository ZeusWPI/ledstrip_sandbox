module script.lua.lua_script;
// dfmt off

import ledstrip.led : Led;
import script.lua.internal.lua_script_task : LuaScriptTask;
import script.script : Script;

import core.time : Duration;

import vibe.core.core : runWorkerTaskH;
import vibe.core.task : Task;

@safe:

final shared
class LuaScript : Script
{
    this(string scriptString, size_t ledCount)
    {
        super(scriptString, ledCount);
    }

    override
    Task start()
    {
        super.start;
        return runWorkerTaskH(&LuaScriptTask.entrypoint, this);
    }

    override
    Duration runtimeSinceLastPause()
        => Duration.zero;
}
