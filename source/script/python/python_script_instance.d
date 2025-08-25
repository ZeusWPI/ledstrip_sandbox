module script.python.python_script_instance;

import script.python.python_script_instance_thread : PythonScriptInstanceThread;
import script.script_instance : ScriptExtension, ScriptInstance;

@safe:

final shared
class PythonScriptInstance : ScriptInstance
{
    this(string name, string sourceFileName, uint ledCount, bool autoStart)
    {
        super(name, sourceFileName, ledCount, autoStart);
    }

scope:
    override
    ThreadEntrypoint threadEntrypoint()
        => &PythonScriptInstanceThread.entrypoint;

    override pure nothrow @nogc
    ScriptExtension extension() const
        => ScriptExtension.python;
}
