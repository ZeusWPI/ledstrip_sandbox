module script.bf.bf_script_instance;

import script.bf.bf_script_instance_thread : BfScriptInstanceThread;
import script.script_instance : ScriptExtension, ScriptInstance;

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
class BfScriptInstance : ScriptInstance
{
    this(string name, string sourceFileName, uint ledCount, bool autoStart)
    {
        super(name, sourceFileName, ledCount, autoStart);
    }

scope:
    override
    ThreadEntrypoint threadEntrypoint()
        => &BfScriptInstanceThread.entrypoint;

    override pure nothrow @nogc
    ScriptExtension extension() const
        => ScriptExtension.bf;
}
