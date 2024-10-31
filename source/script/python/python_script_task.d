module script.python.python_script_task;

import script.python.python_script : PythonScript;
import script.script : Script;
import script.script_task : ScriptTask;
import thread_manager : ThreadManager;

import std.exception : basicExceptionCtors, enforce;

import pyd.def : py_init, py_finish;
import pyd.embedded : InterpContext, py_eval;

import vibe.core.core : yield;
import vibe.core.log;
import vibe.core.task : InterruptException;
import vibe.core.process;
import script.python.python_lib;

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
class PythonScriptTask : ScriptTask
{
    private alias enf = enforce!PythonScriptTaskException;

    static nothrow
    void entrypoint(Script script)
    in (
        ThreadManager.constInstance.inScriptTaskPool,
        "PythonScriptTask: entrypoint must be called from a script task",
    )
    {
        PythonScriptTask instance;
        try
            instance = new typeof(this)(script);
        catch (Exception e)
            logError("PythonScriptTask entrypoint failed: %s", (() @trusted => e.toString)());
        instance.run;
    }

    protected
    this(Script script)
    {
        super(script);
        enf(cast(PythonScript) script, "Script is not a PythonScript");
    }

    protected override nothrow
    void run()
    {
        scope (exit)
        {
            m_script.setStopped;
        }

        logInfo(`Task for python script "%s" started`, m_script.name);

        try
        {
            (() @trusted {
                InterpContext ctx = (() @trusted => new InterpContext)();
                ctx.sourceCode = script.sourceCode;
                ctx.sandboxGlobals = PythonLib.buildGlobals;
                ctx.sandboxLocals = py_eval("dict()");
                ctx.py_eval("exec(sourceCode, sandboxGlobals, sandboxLocals)");
            })();
            logInfo(`Task for python script "%s" exited normally`, m_script.name);
        }
        catch (InterruptException e)
        {
            logInfo(`Task for python script "%s" exited by interruption`, m_script.name);
        }
        catch (Exception e)
        {
            logError(
                `Task for python script "%s" failed: %s`,
                m_script.name, (() @trusted => e.toString)(),
            );
        }
    }

    static nothrow
    PythonScriptTask instance()
        => cast(PythonScriptTask) super.instance;

    static nothrow
    const(PythonScriptTask) constInstance()
        => cast(const(PythonScriptTask)) super.constInstance;

    pure nothrow @nogc
    PythonScript pythonScript()
        => cast(PythonScript) script;

    pure nothrow @nogc
    const(PythonScript) constPythonScript() const
        => cast(const(PythonScript)) constScript;
}

class PythonScriptTaskException : Exception
{
    mixin basicExceptionCtors;
}
