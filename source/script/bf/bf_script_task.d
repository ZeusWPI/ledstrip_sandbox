module script.bf.bf_script_task;

import script.script_task : ScriptTask;
import ledstrip.led : Led;
import ledstrip.ledstrip : Ledstrip;
import script.bf.bf_script : BfScript;
import script.script : Script;
import util : sleepFrameFraction;
import thread_manager : ThreadManager;

import std.algorithm : canFind, filter;
import std.conv : to;
import std.exception : basicExceptionCtors, enforce;
import std.format : f = format;
import std.range : chunks, enumerate;

import vibe.core.core : yield;
import vibe.core.log;
import vibe.core.task : InterruptException;

@safe:

final
class BfScriptTask : ScriptTask
{
    private alias enf = enforce!BfScriptTaskException;

    private enum string ct_instructionSet = "><+-.,[]";

    static nothrow
    void entrypoint(Script script)
    in (
        ThreadManager.constInstance.inScriptTaskPool,
        "BfScriptTask: entrypoint must be called from a script task",
    )
    {
        BfScriptTask instance;
        try
            instance = new typeof(this)(script);
        catch (Exception e)
            logError("BfScriptTask entrypoint failed: %s", (() @trusted => e.toString)());
        instance.run;
    }

    protected
    this(Script script)
    {
        super(script);
        enf(cast(BfScript) script, "Script is not a BfScript");
    }

    protected override nothrow
    void run()
    {
        scope (exit)
        {
            m_script.setStopped;
        }

        logInfo(`Task for bf script "%s" started`, m_script.name);

        try
        {
            immutable string code = filterInstructions;
            const size_t[size_t] bracketMap = makeBracketMap(code);
            ubyte[] tape = new ubyte[m_script.leds.length * 3];
            size_t tapePtr;

            logDiagnostic(`Bf script "%s" source code after filtering: "%s"`, m_script.name, code);

            ulong lastFrameCount;
            int ticksSinceLastYield;
            for (size_t ip = 0; ip < code.length; ip++)
            {
                ulong currFrameCount = Ledstrip.constInstance.frameCount;
                if (currFrameCount != lastFrameCount)
                {
                    foreach (i, chunk; tape.chunks(3).enumerate)
                        m_script.leds[i] = Led(chunk[0], chunk[1], chunk[2]);
                    m_script.setLedsChanged;
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
                    while (Ledstrip.constInstance.frameCount == lastFrameCount)
                        sleepFrameFraction(5);
                    ticksSinceLastYield = 0;
                    break;
                case '.':
                    logInfo(
                        `Bf script "%s" dump instruction ('.'): ip=%u, tapePtr=%u, value=%u, tape=%s`,
                        m_script.name, ip, tapePtr, tape[tapePtr], tape,
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
            logInfo(`Task for bf script "%s" exited normally`, m_script.name);
        }
        catch (InterruptException e)
        {
            logInfo(`Task for bf script "%s" exited by interruption`, m_script.name);
        }
        catch (Exception e)
        {
            logError(
                `Task for bf script "%s" failed: %s`,
                m_script.name, (() @trusted => e.toString)(),
            );
        }
    }

    private nothrow
    string filterInstructions()
    {
        try
        {
            return m_script.sourceCode
                .filter!(c => ct_instructionSet.canFind(c))
                .to!string;
        }
        catch (Exception e)
        {
            assert(
                false,
                f!`Task for lua script "%s": Fatal error creating LuaState: %s`(
                    m_script.name, (() @trusted => e.toString)(),
            )
            );
        }
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
                enf(
                    stack.length,
                    f!`Task for bf script "%s": Found unmatched ]`(m_script.name),
                );
                bracketMap[stack[$ - 1]] = i;
                bracketMap[i] = stack[$ - 1];
                stack = stack[0 .. $ - 1];
            }
        }
        enf(
            !stack.length,
            f!`Task for bf script "%s": Found unmatched [`(m_script.name),
        );

        return bracketMap;
    }
}

class BfScriptTaskException : Exception
{
    mixin basicExceptionCtors;
}
