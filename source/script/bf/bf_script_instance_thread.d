module script.bf.bf_script_instance_thread;

import ledstrip.led : Led;
import ledstrip.ledstrip : Ledstrip;
import script.bf.bf_script_instance : BfScriptInstance;
import script.script_instance : ScriptInstance;
import script.script_instance_thread : ScriptInstanceThread;
import thread_manager : inThreadKind, ThreadKind;
import util : sleepFrameFraction;

import std.algorithm : canFind, filter;
import std.conv : to;
import std.exception : basicExceptionCtors, enforce;
import std.format : f = format;
import std.range : chunks, enumerate;

import vibe.core.log;

@safe:

final
class BfScriptInstanceThread : ScriptInstanceThread
{
    private alias enf = enforce!BfScriptInstanceThreadException;

    private enum string ct_instructionSet = "><+-.,[]";

    static nothrow
    void entrypoint(ScriptInstance scriptInstance)
    in (inThreadKind(ThreadKind.scriptInstance), "BfScriptInstanceThread: entrypoint must be called from a script instance thread")
    {
        BfScriptInstanceThread instance;
        try
            instance = new typeof(this)(scriptInstance);
        catch (Exception e)
            logError("BfScriptInstanceThread entrypoint failed: %s", (() @trusted => e.toString)());
        instance.run;
    }

    protected
    this(ScriptInstance scriptInstance)
    {
        super(scriptInstance);
        enf(cast(BfScriptInstance) scriptInstance, "ScriptInstance is not a BfScriptInstance");
    }

    protected override nothrow
    void run()
    {
        scope (exit)
        {
            m_scriptInstance.setStopped;
        }

        logInfo(`Thread for bf script instance "%s" started`, m_scriptInstance.name);

        try
        {
            immutable string code = filterInstructions;
            const size_t[size_t] bracketMap = makeBracketMap(code);
            ubyte[] tape = new ubyte[m_scriptInstance.leds.length * 3];
            size_t tapePtr;

            logDiagnostic(`Bf script instance "%s" source code after filtering: "%s"`, m_scriptInstance.name, code);

            ulong lastFrameCount;
            for (size_t ip = 0; ip < code.length; ip++)
            {
                ulong currFrameCount = Ledstrip.constInstance.frameCount;
                if (currFrameCount != lastFrameCount)
                {
                    foreach (i, chunk; tape.chunks(3).enumerate)
                        m_scriptInstance.leds[i] = Led(chunk[0], chunk[1], chunk[2]);
                    m_scriptInstance.setLedsChanged;
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
                    break;
                case '.':
                    logInfo(
                        `Bf script instance "%s" dump instruction ('.'): ip=%u, tapePtr=%u, value=%u, tape=%s`,
                        m_scriptInstance.name, ip, tapePtr, tape[tapePtr], tape,
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
            }
            logInfo(`Thread for bf script instance "%s" exited normally`, m_scriptInstance.name);
        }
        catch (Exception e)
        {
            logError(
                `Thread for bf script instance "%s" failed: %s`,
                m_scriptInstance.name, (() @trusted => e.toString)(),
            );
        }
    }

    private nothrow
    string filterInstructions()
    {
        try
        {
            return m_scriptInstance.sourceCode
                .filter!(c => ct_instructionSet.canFind(c))
                .to!string;
        }
        catch (Exception e)
        {
            assert(
                false,
                f!`Thread for bf script instance "%s": Fatal error filtering instructions: %s`(
                    m_scriptInstance.name, (() @trusted => e.toString)(),
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
                    f!`Thread for bf script instance "%s": Found unmatched ]`(m_scriptInstance.name),
                );
                bracketMap[stack[$ - 1]] = i;
                bracketMap[i] = stack[$ - 1];
                stack = stack[0 .. $ - 1];
            }
        }
        enf(
            !stack.length,
            f!`Thread for bf script instance "%s": Found unmatched [`(m_scriptInstance.name),
        );

        return bracketMap;
    }

    static nothrow
    BfScriptInstanceThread instance()
        => cast(BfScriptInstanceThread) super.instance;

    static nothrow
    const(BfScriptInstanceThread) constInstance()
        => cast(const(BfScriptInstanceThread)) super.constInstance;

    pure nothrow @nogc
    BfScriptInstance bfScriptInstance()
        => cast(BfScriptInstance) scriptInstance;

    pure nothrow @nogc
    const(BfScriptInstance) constBfScriptInstance() const
        => cast(const(BfScriptInstance)) constScriptInstance;
}

class BfScriptInstanceThreadException : Exception
{
    mixin basicExceptionCtors;
}
