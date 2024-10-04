module webserver.rest_api_impl;

import ledstrip.ledstrip_states;
import ledstrip.ledstrip_state;
import ledstrip.ledstrip_segment;
import ledstrip.led_positions : getKelderLedPositions, LedPositions;
import main : Main;
import webserver.mailbox : Mailbox;
import webserver.rest_api : RestApi, ScriptApi, SegmentApi, SourceFileApi, StateApi;

import vibe.data.json : Json, serializeToJson;
import vibe.web.rest : Collection;
import vibe.http.common : enforceHTTP, HTTPStatus;

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
        const LedstripStates states = Main.instance.states;
        State[string] aa;
        foreach (key, value; states.states)
            aa[key] = State(key, false);
        aa[states.activeState.name].active = true;
        return aa;
    }

    State get(string _state)
    {
        const LedstripStates states = Main.instance.states;
        enforceHTTP(_state in states.states, HTTPStatus.notFound, "No such state");
        return State(_state, states.activeState.name == _state);
    }

    void postActivate(string _state)
    {
        Main.instance.states.setActiveState(_state);
    }

    Collection!SegmentApi segments(string _state)
        => Collection!SegmentApi(m_segmentApi, _state);
}

class SegmentApiImpl : SegmentApi
{
    Segment[] get(string _state)
    {
        const LedstripStates states = Main.instance.states;
        enforceHTTP(_state in states.states, HTTPStatus.notFound, "No such state");
        const LedstripState state = states.states[_state];
        Segment[] arr;
        foreach (const LedstripSegment seg; state.segments)
            arr ~= Segment(seg.begin, seg.end, /*seg.script.uuid*/ "someid");
        return arr;
    }

    Segment get(string _state, uint _begin)
    {
        const LedstripStates states = Main.instance.states;
        enforceHTTP(_state in states.states, HTTPStatus.notFound, "No such state");
        const LedstripState state = states.states[_state];
        enforceHTTP(_begin in state.segments, HTTPStatus.notFound, "No segment with provided begin led");
        const LedstripSegment seg = state.segments[_begin];
        return Segment(seg.begin, seg.end, /*seg.script.uuid*/ "someid");
    }
}

class ScriptApiImpl : ScriptApi
{
}

class SourceFileApiImpl : SourceFileApi
{
}
