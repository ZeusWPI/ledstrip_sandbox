module script.python.python_script;

import script.python.python_script_task : PythonScriptTask;
import script.script : Script;

@safe:

final shared
class PythonScript : Script
{
    this(string name, string fileName, uint ledCount, bool autoStart)
    {
        super(name, fileName, ledCount, autoStart);
    }

    override
    TaskEntrypoint taskEntrypoint()
        => &PythonScriptTask.entrypoint;
}
