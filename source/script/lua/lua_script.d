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
    private Task m_task;

    this(string scriptString, size_t ledCount)
    {
        super(scriptString, ledCount);
    }

    ~this()
    {
    }

    override
    void start()
    {
        super.start;
        m_task = runWorkerTaskH(&LuaScriptTask.entrypoint, this);
    }

    override nothrow
    void reset()
    {
        super.reset;
    }

    override
    Duration runtimeSinceLastPause()
        => Duration.zero;
}
