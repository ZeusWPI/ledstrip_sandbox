module script.python.python_script_instance_task;

import script.python.python_script_instance : PythonScriptInstance;
import script.python.python_lib : PythonLib;
import script.script_instance : ScriptInstance;
import script.script_instance_task : ScriptInstanceTask;
import thread_manager : ThreadManager;

import std.exception : basicExceptionCtors, enforce;

import pyd.def : py_init, py_finish;
import pyd.embedded : InterpContext, py_eval;

import vibe.core.core : yield;
import vibe.core.log;
import vibe.core.task : InterruptException;
import vibe.core.process;

@safe:

@trusted
shared static this()
{
    py_init;
}

@trusted
shared static ~this()
{
    py_finish;
}

final
class PythonScriptInstanceTask : ScriptInstanceTask
{
    private alias enf = enforce!PythonScriptInstanceTaskException;

    static nothrow
    void entrypoint(ScriptInstance scriptInstance)
    in (
        ThreadManager.constInstance.inScriptInstanceTaskPool,
        "PythonScriptInstanceTask: entrypoint must be called from a script instance task",
    )
    {
        PythonScriptInstanceTask instance;
        try
            instance = new typeof(this)(scriptInstance);
        catch (Exception e)
            logError("PythonScriptInstanceTask entrypoint failed: %s", (() @trusted => e.toString)());
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

        logInfo(`Task for python script instance "%s" started`, m_scriptInstance.name);

        try
        {
            (() @trusted {
                InterpContext ctx = (() @trusted => new InterpContext)();
                ctx.sourceCode = m_scriptInstance.sourceCode;
                ctx.sandboxGlobals = PythonLib.buildGlobals;
                ctx.sandboxLocals = py_eval("dict()");
                ctx.py_eval("exec(sourceCode, sandboxGlobals, sandboxLocals)");
            })();
            logInfo(`Task for python script instance "%s" exited normally`, m_scriptInstance.name);
        }
        catch (InterruptException e)
        {
            logInfo(
                `Task for python script instance "%s" exited by interruption`,
                m_scriptInstance.name,
            );
        }
        catch (Exception e)
        {
            logError(
                `Task for python script instance "%s" failed: %s`,
                m_scriptInstance.name, (() @trusted => e.toString)(),
            );
        }
    }

    static nothrow
    PythonScriptInstanceTask instance()
        => cast(PythonScriptInstanceTask) super.instance;

    static nothrow
    const(PythonScriptInstanceTask) constInstance()
        => cast(const(PythonScriptInstanceTask)) super.constInstance;

    pure nothrow @nogc
    PythonScriptInstance pythonScriptInstance()
        => cast(PythonScriptInstance) scriptInstance;

    pure nothrow @nogc
    const(PythonScriptInstance) constPythonScriptInstance() const
        => cast(const(PythonScriptInstance)) constScriptInstance;
}

class PythonScriptInstanceTaskException : Exception
{
    mixin basicExceptionCtors;
}
