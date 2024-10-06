module webserver.rest_api_impl;

import data_dir : DataDir;
import ledstrip.ledstrip_states : LedstripStates;
import ledstrip.ledstrip_state : LedstripState;
import ledstrip.ledstrip_segment : LedstripSegment;
import script.script : RealScript = Script;
import ledstrip.led_positions : getKelderLedPositions;
import main : Main;
import webserver.mailbox : Mailbox;
import webserver.rest_api : RestApi, ScriptApi, SegmentApi, SourceFileApi, StateApi;

import std.format : f = format;

import vibe.data.json : Json, serializeToJson;
import vibe.web.rest : Collection;
import vibe.http.common : enforceHTTP, HTTPStatus, HTTPStatusException;

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
    string[] get()
    {
        string[] names;
        foreach (name, realScript; Main.constInstance.scripts)
            names ~= name;
        return names;
    }

    Script get(string _name)
    {
        enforceHTTP(_name in Main.constInstance.scripts, HTTPStatus.notFound, "No such script");
        const RealScript realScript = Main.constInstance.scripts[_name];
        return Script(
            realScript.name,
            realScript.fileName,
            cast(uint) realScript.leds.length,
        );
    }
}

class SourceFileApiImpl : SourceFileApi
{
    string[] get()
        => DataDir.listScripts;

    SourceFile get(string _name)
    {
        string sourceCode;
        try
        {
            sourceCode = DataDir.loadScript(_name);
        }
        catch (Exception e)
        {
            throw new HTTPStatusException(
                HTTPStatus.notFound,
                f!`Can't load source file "%s": %s`(_name, e.msg),
            );
        }

        return SourceFile(_name, sourceCode);
    }
}
