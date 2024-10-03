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
    Collection!StateApi states();

    Collection!ScriptApi scripts();

    Collection!SourceFileApi sourceFiles();

    @path("/mailbox.json")
    void putMailbox(string topic, string message);

    Json getLedPositions();
}

interface StateApi
{
    struct CollectionIndices {
        string _state;
    }

    struct State
    {
        bool active;
    }

    State[string] get();

    State get(string _state);

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
        string scriptUuid;
    }

    Segment[] get(string _state);

    Segment get(string _state, uint _begin);
}

interface ScriptApi
{
    struct CollectionIndices {
        string _id;
    }
}

interface SourceFileApi
{
    struct CollectionIndices {
        string _id;
    }
}
