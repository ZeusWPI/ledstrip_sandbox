module script.lua.lua_script;
// dfmt off

import ledstrip.led : Led;
import script.lua.internal.lua_script_task : LuaScriptTask;
import script.script : Script;

import core.time : Duration;

import vibe.core.core : runWorkerTaskH;
import vibe.core.task : Task;
import vibe.core.taskpool : TaskPool;

@safe:

final shared
class LuaScript : Script
{
    this(string scriptFileName, string scriptString, size_t ledCount)
    {
        super(scriptFileName, scriptString, ledCount);
    }

    override
    Task start(TaskPool taskPool)
    {
        super.start(taskPool);
        return taskPool.runTaskH(&LuaScriptTask.entrypoint, this);
    }

    override
    Duration runtimeSinceLastPause()
        => Duration.zero;
}
