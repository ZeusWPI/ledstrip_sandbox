module script.bf.internal.bf_script_task;
// dfmt off

import ledstrip.led : Led;
import ledstrip.ledstrip : frameCount;
import script.bf.bf_script : BfScript;
import script.script : Script;

import core.time : Duration;

import std.algorithm : canFind, filter;
import std.conv : to;
import std.exception : basicExceptionCtors, enforce;
import std.format : f = format;
import std.math : abs;
import std.range : chunks, enumerate;

import vibe.core.core : InterruptException, Task, yield;
import vibe.core.log;

@safe:
package:

package(script.bf) final // @suppress(dscanner.suspicious.redundant_attributes)
class BfScriptTask
{
    private BfScript m_script;
    private Task m_task;

    @disable this(ref typeof(this));

    private nothrow
    this(BfScript script)
    in (script !is null)
    {
        m_script = script;
        m_task = Task.getThis;
    }

    private nothrow
    void run()
    {
        scope (exit) m_script.reset;

        try
        {
            immutable string code = filterInstructions;
            const size_t[size_t] bracketMap = makeBracketMap(code);
            ubyte[] tape = new ubyte[m_script.leds.length * 3];
            size_t tapePtr;

            logInfo("bf: %s", code);

            ulong lastFrameCount;
            int ticksSinceLastYield;
            for (size_t ip = 0; ip < code.length; ip++)
            {
                ulong currFrameCount = frameCount;
                if (currFrameCount != lastFrameCount)
                {
                    foreach (i, chunk; tape.chunks(3).enumerate)
                        m_script.leds[i] = Led(chunk[0], chunk[1], chunk[2]);
                    lastFrameCount = currFrameCount;
                }

                final switch (code[ip])
                {
                case '>':
                    if (tapePtr + 1 == tape.length)
                        tapePtr = 0;
                    else
                        tapePtr++;
                    break;
                case '<':
                    if (tapePtr == 0)
                        tapePtr = tape.length;
                    tapePtr--;
                    break;
                case '+':
                    tape[tapePtr]++;
                    break;
                case '-':
                    tape[tapePtr]--;
                    break;
                case ',':
                    while (frameCount == lastFrameCount)
                        yield;
                    ticksSinceLastYield = 0;
                    break;
                case '.':
                    logInfo(
                        "bf '.': ip=%u, tapePtr=%u, value=%u, tape=%s",
                        ip, tapePtr, tape[tapePtr], tape,
                    );
                    break;
                case '[':
                    if (tape[tapePtr] == 0)
                        ip = bracketMap[ip];
                    break;
                case ']':
                    if (tape[tapePtr] != 0)
                        ip = bracketMap[ip];
                    break;
                }

                ticksSinceLastYield++;
                if (ticksSinceLastYield == 10)
                {
                    yield;
                    ticksSinceLastYield = 0;
                }
            }
            logInfo("bf script task exited normally");
        }
        catch (InterruptException e)
        {
            logInfo("bf script task interrupted");
            return;
        }
        catch (Exception e)
        {
            logError("bf script failed: %s", (() @trusted => e.toString)());
        }
    }

    private pure nothrow
    string filterInstructions()
    {
        scope (failure) assert(false, "filterInstructions failed");

        static immutable string instructionSet = "><+-.,[]";
        return m_script.scriptString
            .filter!(c => instructionSet.canFind(c))
            .to!string;
    }

    private pure
    size_t[size_t] makeBracketMap(string code)
    {
        size_t[size_t] bracketMap;
        size_t[] stack;

        foreach (i, c; code)
        {
            if (c == '[')
            {
                stack ~= i;
            }
            else if (c == ']')
            {
                enforce!BfException(stack.length, "bf: Found unmatched ]");
                bracketMap[stack[$ - 1]] = i;
                bracketMap[i] = stack[$ - 1];
                stack = stack[0 .. $ - 1];
            }
        }
        enforce!BfException(!stack.length, "bf: Found unmatched [");

        return bracketMap;
    }

    package(script.bf) static nothrow
    void entrypoint(BfScript script)
    {
        BfScriptTask instance = new BfScriptTask(script);
        instance.run;
    }
}

class BfException : Exception
{
    mixin basicExceptionCtors;
}
