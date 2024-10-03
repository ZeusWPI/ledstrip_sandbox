module webserver.rest_api_impl;

import ledstrip.led_assignments : LedAssignments, Segment;
import ledstrip.led_positions : getKelderLedPositions, LedPositions;
import main : Main;
import webserver.mailbox : Mailbox;
import webserver.rest_api : RestApi, ScriptApi, SegmentApi, SourceFileApi, StateApi;

import vibe.data.json : Json, serializeToJson;
import vibe.web.rest : Collection;

@safe:

final
class RestApiImpl : RestApi
{
    private StateApi m_stateApi;
    private ScriptApiImpl m_scriptApi;
    private SourceFileApiImpl m_sourceFileApi;

    this()
    {
        m_stateApi = new StateApiImpl;
        m_scriptApi = new ScriptApiImpl;
        m_sourceFileApi = new SourceFileApiImpl;
    }

    override
	Collection!StateApi states()
        => Collection!StateApi(m_stateApi);

    override
	Collection!ScriptApi scripts()
        => Collection!ScriptApi(m_scriptApi);

    override
	Collection!SourceFileApi sourceFiles()
        => Collection!SourceFileApi(m_sourceFileApi);

    override
    void putMailbox(string topic, string message)
    {
        Mailbox.putMailbox(topic, message);
    }

    override
    Json getLedPositions()
        => getKelderLedPositions.serializeToJson;


}

class StateApiImpl : StateApi
{
    private SegmentApiImpl m_segmentApi;

    this()
    {
        m_segmentApi = new SegmentApiImpl;
    }

    State[string] get()
    {
        return null;
    }

    State get(string _state)
    {
        return State.init;
    }

    void postActivate(string _state)
    {
    }

    Collection!SegmentApi segments(string _state)
        => Collection!SegmentApi(m_segmentApi, _state);
}

class SegmentApiImpl : SegmentApi
{
	Segment[] get(string _state)
    {
        return [];
    }

	Segment get(string _state, uint _begin)
    {
        return Segment.init;
    }
}

class ScriptApiImpl : ScriptApi
{
}

class SourceFileApiImpl : SourceFileApi
{
}
