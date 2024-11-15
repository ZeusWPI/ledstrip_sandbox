module webserver.rest_api;

import vibe.data.json : Json;
import vibe.web.rest : Collection, path;

@safe:

@path("/api")
interface RestApi
{
    ConfigApi config();

    Collection!StateApi states();

    string getActiveState();

    Collection!ScriptInstanceApi scriptInstances();

    Collection!ScriptSourceFileApi scriptSourceFiles();

    @path("/mailbox.json")
    void putMailbox(string topic, string message);

    Json getLedPositions();
}

interface ConfigApi
{
    uint getFps();

    void putFps(uint fps);

    ubyte getMaxBrightness();

    void putMaxBrightness(ubyte maxBrightness);
}

interface StateApi
{
    struct CollectionIndices
    {
        string _state;
    }

    string[] get();

    void post(string state);

    string get(string _state);

    void delete_(string _state);

    void postActivate(string _state);

    Collection!SegmentApi segments(string _state);
}

interface SegmentApi
{
    struct CollectionIndices
    {
        string _state;
        uint _begin;
    }

    struct SegmentPod
    {
        uint begin, end;
        string scriptInstanceName;
    }

    SegmentPod[] get(string _state);

    void post(string _state, SegmentPod segment);

    SegmentPod get(string _state, uint _begin);

    void delete_(string _state, uint _begin);
}

interface ScriptInstanceApi
{
    struct CollectionIndices
    {
        string _name;
    }

    struct ScriptInstancePod
    {
        string name;
        string sourceFileName;
        uint ledCount;
        bool autoStart;
    }

    string[] get();

    void post(ScriptInstancePod scriptInstance);

    ScriptInstancePod get(string _name);

    void delete_(string _name);

    bool getRunning(string _name);

    void postStart(string _name);

    void postStop(string _name);

    void postReload(string _name);
}

interface ScriptSourceFileApi
{
    struct CollectionIndices
    {
        string _name;
    }

    struct ScriptSourceFilePod
    {
        string name;
        string sourceCode;
    }

    string[] get();

    void post(ScriptSourceFilePod scriptSourceFile);

    ScriptSourceFilePod get(string _name);

    void put(string _name, string sourceCode);

    void delete_(string _name);
}
