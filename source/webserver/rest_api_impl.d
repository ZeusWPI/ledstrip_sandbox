module webserver.rest_api_impl;

import data_dir : DataDir;
import ledstrip.led_positions : getKelderLedPositions;
import ledstrip.ledstrip_segment : LedstripSegment;
import ledstrip.ledstrip_state : LedstripState;
import ledstrip.ledstrip_states : LedstripStates;
import script.script : RealScript = Script;
import script.scripts : Scripts;
import webserver.mailbox : Mailbox;
import webserver.rest_api : ConfigApi, RestApi, ScriptApi, SegmentApi, SourceFileApi, StateApi;

import std.format : f = format;

import vibe.data.json : Json, serializeToJson;
import vibe.http.common : enforceHTTP, HTTPStatus, HTTPStatusException;
import vibe.web.rest : Collection;

@safe:

final
class RestApiImpl : RestApi
{
    private ConfigApi m_configApi;
    private StateApi m_stateApi;
    private ScriptApiImpl m_scriptApi;
    private SourceFileApiImpl m_sourceFileApi;

    this()
    {
        m_configApi = new ConfigApiImpl;
        m_stateApi = new StateApiImpl;
        m_scriptApi = new ScriptApiImpl;
        m_sourceFileApi = new SourceFileApiImpl;
    }

    override
    ConfigApi config()
        => m_configApi;

    override
    Collection!StateApi states()
        => Collection!StateApi(m_stateApi);

    override
    string getActiveState()
        => LedstripStates.constInstance.activeState.name;

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

class ConfigApiImpl : ConfigApi
{
    override
    uint getFps()
        => DataDir.constInstance.config.fps;

    override
    void putFps(uint fps)
    {
        enforceHTTP(DataDir.isValidFps(fps), HTTPStatus.conflict, "Invalid fps");
        DataDir.instance.config.fps = fps;
        DataDir.instance.saveConfig;
    }
}

class StateApiImpl : StateApi
{
    private SegmentApiImpl m_segmentApi;

    this()
    {
        m_segmentApi = new SegmentApiImpl;
    }

    override
    string[] get()
    {
        const LedstripStates states = LedstripStates.constInstance;
        string[] arr;
        foreach (name, state; states.states)
            arr ~= name;
        return arr;
    }

    override
    void post(string state)
    {
        enforceHTTP(state !in LedstripStates.constInstance.states, HTTPStatus.conflict, "State already exists");
        LedstripStates.instance.addState(state);
    }

    override
    string get(string _state)
    {
        const LedstripStates states = LedstripStates.constInstance;
        enforceHTTP(_state in states.states, HTTPStatus.notFound, "No such state");
        return _state;
    }

    override
    void delete_(string _state)
    {
        enforceHTTP(_state in LedstripStates.constInstance.states, HTTPStatus.notFound, "No such state");
        LedstripStates.instance.removeState(_state);
    }

    override
    void postActivate(string _state)
    {
        LedstripStates.instance.setActiveState(_state);
    }

    override
    Collection!SegmentApi segments(string _state)
        => Collection!SegmentApi(m_segmentApi, _state);
}

class SegmentApiImpl : SegmentApi
{
    override
    Segment[] get(string _state)
    {
        const LedstripStates states = LedstripStates.constInstance;
        enforceHTTP(_state in states.states, HTTPStatus.notFound, "No such state");
        const LedstripState state = states.states[_state];
        Segment[] arr;
        foreach (const LedstripSegment seg; state.segments)
            arr ~= Segment(seg.begin, seg.end, seg.script.name);
        return arr;
    }

    override
    Segment get(string _state, uint _begin)
    {
        const LedstripStates states = LedstripStates.constInstance;
        enforceHTTP(_state in states.states, HTTPStatus.notFound, "No such state");
        const LedstripState state = states.states[_state];
        enforceHTTP(_begin in state.segments, HTTPStatus.notFound, "No segment with provided begin led");
        const LedstripSegment seg = state.segments[_begin];
        return Segment(seg.begin, seg.end, seg.script.name);
    }
}

class ScriptApiImpl : ScriptApi
{
    override
    string[] get()
    {
        string[] names;
        foreach (name, realScript; Scripts.constInstance.scripts)
            names ~= name;
        return names;
    }

    override
    Script get(string _name)
    {
        enforceHTTP(_name in Scripts.constInstance.scripts, HTTPStatus.notFound, "No such script");
        const RealScript realScript = Scripts.constInstance.scripts[_name];
        return Script(
            realScript.name,
            realScript.fileName,
            cast(uint) realScript.leds.length,
        );
    }
}

class SourceFileApiImpl : SourceFileApi
{
    override
    string[] get()
        => DataDir.constInstance.listScripts;

    override
    SourceFile get(string _name)
    {
        string sourceCode;
        try
        {
            sourceCode = DataDir.constInstance.loadScript(_name);
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
