module webserver.rest_api;

import vibe.data.json : Json;
import vibe.web.rest : Collection, path;

@safe:

// TODO:
// Fancier mailbox
// Collections:
//   Segment readAll, create, read, delete
//   Script readAll, create, read, start, stop, debug...
//   Sourcefile readAll, create, read, update, delete

@path("/api")
interface RestApi
{
    ConfigApi config();

    Collection!StateApi states();

    string getActiveState();

    Collection!ScriptApi scripts();

    Collection!SourceFileApi sourceFiles();

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
    struct CollectionIndices {
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
    struct CollectionIndices {
        string _state;
        uint _begin;
    }

    struct Segment
    {
        uint begin, end;
        string scriptName;
    }

    Segment[] get(string _state);

    void post(string _state, Segment segment);

    Segment get(string _state, uint _begin);

    void delete_(string _state, uint _begin);
}

interface ScriptApi
{
    struct CollectionIndices {
        string _name;
    }

    struct Script {
        string name;
        string fileName;
        uint ledCount;
        bool autoStart;
    }

    string[] get();

    void post(Script script);

    Script get(string _name);

    void delete_(string _name);

    bool getRunning(string _name);

    void postStart(string _name);

    void postStop(string _name);

    void postReload(string _name);
}

interface SourceFileApi
{
    struct CollectionIndices {
        string _name;
    }

    struct SourceFile {
        string name;
        string sourceCode;
    }

    string[] get();

    void post(SourceFile sourceFile);

    SourceFile get(string _name);

    void put(string _name, string sourceCode);

    void delete_(string _name);
}
