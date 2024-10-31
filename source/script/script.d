module script.script;

import data_dir : DataDir;
import ledstrip.led : Led;

import std.algorithm : canFind, endsWith;
import std.exception : basicExceptionCtors, enforce;
import std.format : f = format;
import std.traits : EnumMembers;

@safe:

abstract shared
class Script
{
    private alias enf = enforce!ScriptException;

    alias TaskEntrypoint = void function(Script) nothrow @safe;

    private string m_name;
    private string m_fileName;
    private uint m_ledCount;
    private bool m_autoStart;

    private string m_sourceCode;
    private Led[] m_leds;
    private bool m_ledsChanged;
    private bool m_running;

    @disable this(ref typeof(this));

    protected synchronized
    this(string name, string fileName, uint ledCount, bool autoStart)
    {
        enf(name.isValidScriptName, f!`Invalid script name "%s"`(name));
        enf(fileName.isValidScriptFileName, f!`Invalid file name "%s"`(fileName));

        m_name = name;
        m_fileName = fileName;
        m_ledCount = ledCount;
        m_autoStart = autoStart;

        m_sourceCode = DataDir.constInstance.loadScript(fileName);
        if (ledCount > 0)
            m_leds = new Led[ledCount];
    }

    final pure nothrow @nogc
    {
        string name() const
            => m_name;

        string fileName() const
            => m_fileName;

        uint ledCount() const
            => m_ledCount;

        bool autoStart() const
            => m_autoStart;

        string sourceCode() const
            => m_sourceCode;

        inout(shared(Led[])) leds() inout
            => m_leds;

        bool ledsChanged() const
            => m_ledsChanged;

        void setLedsChanged()
        {
            m_ledsChanged = true;
        }

        void resetLedsChanged()
        {
            m_ledsChanged = false;
        }

        bool running() const
            => m_running;

        void setRunning()
        {
            m_running = true;
        }

        void setStopped()
        {
            m_running = false;
        }
    }

    abstract TaskEntrypoint taskEntrypoint();
}

class ScriptException : Exception
{
    mixin basicExceptionCtors;
}

enum ScriptExtension : string
{
    lua = ".lua",
    python = ".py",
    bf = ".bf",
}

pure nothrow @nogc
bool isValidScriptName(string name)
    => name.length > 0;

pure nothrow @nogc
bool isValidScriptFileName(string name)
{
    if (name.canFind("/"))
        return false;

    foreach (string ext; EnumMembers!ScriptExtension)
        if (name.endsWith(ext))
            return true;
    return false;
}
