module script.bf.bf_script;
// dfmt off

import ledstrip.led : Led;
import script.bf.internal.bf_script_task : BfScriptTask;
import script.script : Script;

import core.time : Duration;

import std.exception : enforce;

import vibe.core.core : runWorkerTaskH;
import vibe.core.task : Task;
import vibe.core.taskpool : TaskPool;

@safe:

/** 
 * Bf scripts operate on a circular tape of integers using the Brainfuck language.
 * The tape size equals the amount of assigned leds, times 3.
 * Going out of bounds on either side of the tape simply wraps around.
 * Stored integers start at 0 and can range from 0-255, wrapping around.
 *
 * Every 3 values represent one led, and will be pushed to the ledstrip every frame.
 *
 * The input instruction ',' waits until the next frame.
 * The output instruction '.' dumps debug info about the current state.
 */
final shared
class BfScript : Script
{
    this(string scriptFileName, string scriptString, size_t ledCount)
    {
        super(scriptFileName, scriptString, ledCount);
    }

    override
    Task start(TaskPool taskPool)
    {
        super.start(taskPool);
        return taskPool.runTaskH(&BfScriptTask.entrypoint, this);
    }

    override
    Duration runtimeSinceLastPause()
        => Duration.zero;
}
