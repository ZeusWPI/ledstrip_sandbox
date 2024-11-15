module script.python.python_script_instance;

import script.python.python_script_instance_task : PythonScriptInstanceTask;
import script.script_instance : ScriptInstance;

@safe:

final shared
class PythonScriptInstance : ScriptInstance
{
    this(string name, string sourceFileName, uint ledCount, bool autoStart)
    {
        super(name, sourceFileName, ledCount, autoStart);
    }

    override
    TaskEntrypoint taskEntrypoint()
        => &PythonScriptInstanceTask.entrypoint;
}
