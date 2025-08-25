module script.python.python_script_instance_thread;

import script.python.python_script_instance : PythonScriptInstance;
import script.python.python_lib : PythonLib;
import script.script_instance : ScriptInstance;
import script.script_instance_thread : ScriptInstanceThread;
import thread_manager : inThreadKind, ThreadKind;

import std.exception : basicExceptionCtors, enforce;

import pyd.def : py_init, py_finish;
import pyd.embedded : InterpContext, py_eval;

import vibe.core.log;

@safe:

final
class PythonScriptInstanceThread : ScriptInstanceThread
{
    private alias enf = enforce!PythonScriptInstanceThreadException;

    private __gshared bool g_init;

    static nothrow
    void entrypoint(ScriptInstance scriptInstance)
    in (inThreadKind(ThreadKind.scriptInstance), "PythonScriptInstanceThread: entrypoint must be called from a script instance thread")
    {
        PythonScriptInstanceThread instance;
        try
            instance = new typeof(this)(scriptInstance);
        catch (Exception e)
            logError("PythonScriptInstanceThread entrypoint failed: %s", (() @trusted => e.toString)());
        instance.run;
    }

    protected
    this(ScriptInstance scriptInstance)
    {
        super(scriptInstance);
        enf(cast(PythonScriptInstance) scriptInstance, "scriptInstance is not a PythonScriptInstance");
    }

    protected override nothrow
    void run()
    {
        scope (exit)
        {
            m_scriptInstance.setStopped;
        }

        logInfo(`Thread for python script instance "%s" started`, m_scriptInstance.name);

        try
        {
            (() @trusted {
                synchronized (typeof(this).classinfo)
                {
                    py_init;
                    g_init = true;
                }
                InterpContext ctx = (() @trusted => new InterpContext)();
                ctx.sourceCode = m_scriptInstance.sourceCode;
                ctx.sandboxGlobals = PythonLib.buildGlobals;
                ctx.sandboxLocals = py_eval("dict()");
                ctx.py_eval("exec(sourceCode, sandboxGlobals, sandboxLocals)");
            })();
            logInfo(`Thread for python script instance "%s" exited normally`, m_scriptInstance.name);
        }
        catch (Exception e)
        {
            logError(
                `Thread for python script instance "%s" failed: %s`,
                m_scriptInstance.name, (() @trusted => e.toString)(),
            );
        }
    }

    static nothrow
    PythonScriptInstanceThread instance()
        => cast(PythonScriptInstanceThread) super.instance;

    static nothrow
    const(PythonScriptInstanceThread) constInstance()
        => cast(const(PythonScriptInstanceThread)) super.constInstance;

    pure nothrow @nogc
    PythonScriptInstance pythonScriptInstance()
        => cast(PythonScriptInstance) scriptInstance;

    pure nothrow @nogc
    const(PythonScriptInstance) constPythonScriptInstance() const
        => cast(const(PythonScriptInstance)) constScriptInstance;
}

class PythonScriptInstanceThreadException : Exception
{
    mixin basicExceptionCtors;
}
