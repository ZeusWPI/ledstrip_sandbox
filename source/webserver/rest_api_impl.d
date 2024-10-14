module webserver.rest_api_impl;

import config : ConfigScript, ConfigSegment, ConfigState;
import data_dir : DataDir;
import ledstrip.led_positions : getKelderLedPositions;
import ledstrip.ledstrip : Ledstrip;
import ledstrip.ledstrip_segment : LedstripSegment;
import ledstrip.ledstrip_state : LedstripState, LedstripStateException;
import ledstrip.ledstrip_states : LedstripStates, LedstripStatesException;
import script.lua.internal.lua_lib : LuaLib;
import script.script : RealScript = Script, ScriptException;
import script.scripts : Scripts, ScriptsException;
import webserver.mailbox : Mailbox;
import webserver.rest_api : ConfigApi, RestApi, ScriptApi, SegmentApi, SourceFileApi, StateApi;

import std.algorithm : remove;
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

    override
    string getLuaApiFile()
        => LuaLib.luaApiFile;
}

class ConfigApiImpl : ConfigApi
{
    override
    uint getFps()
        => DataDir.sharedConfig.fps;

    override
    void putFps(uint fps)
    {
        enforceHTTP(DataDir.isValidFps(fps), HTTPStatus.conflict, "Invalid fps");
        DataDir.instance.config.fps = fps;
        DataDir.instance.saveConfig;
    }

    override
    ubyte getMaxBrightness()
        => DataDir.sharedConfig.maxBrightness;

    override
    void putMaxBrightness(ubyte maxBrightness)
    {
        DataDir.instance.config.maxBrightness = maxBrightness;
        DataDir.instance.saveConfig;
        Ledstrip.instance.fullRefresh;
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
        DataDir.instance.config.states[state] = ConfigState();
        DataDir.instance.saveConfig;
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
        DataDir.instance.config.states.remove(_state);
        DataDir.instance.saveConfig;
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
            arr ~= Segment(seg.begin, seg.end, seg.scriptName);
        return arr;
    }

    override
    void post(string _state, Segment segment)
    {
        enforceHTTP(
            _state in LedstripStates.constInstance.states,
            HTTPStatus.notFound,
            "No such state",
        );
        try
        {
            LedstripStates.instance.states[_state].assignSegment(
                segment.begin,
                segment.end,
                segment.scriptName,
            );
        }
        catch (LedstripStatesException e)
            throw new HTTPStatusException(HTTPStatus.conflict, e.msg, __FILE__, __LINE__, e);
        catch (LedstripStateException e)
            throw new HTTPStatusException(HTTPStatus.conflict, e.msg, __FILE__, __LINE__, e);
        DataDir.instance.config.states[_state].segments ~= ConfigSegment(
            segment.begin,
            segment.end,
            segment.scriptName,
        );
        DataDir.instance.saveConfig;
    }

    override
    Segment get(string _state, uint _begin)
    {
        const LedstripStates states = LedstripStates.constInstance;
        enforceHTTP(_state in states.states, HTTPStatus.notFound, "No such state");
        const LedstripState state = states.states[_state];
        enforceHTTP(_begin in state.segments, HTTPStatus.notFound, "No segment with provided begin led");
        const LedstripSegment seg = state.segments[_begin];
        return Segment(seg.begin, seg.end, seg.scriptName);
    }

    override
    void delete_(string _state, uint _begin)
    {
        enforceHTTP(
            _state in LedstripStates.constInstance.states,
            HTTPStatus.notFound,
            "No such state",
        );
        enforceHTTP(
            _begin in LedstripStates.constInstance.states[_state].segments,
            HTTPStatus.notFound,
            "No such segment",
        );
        LedstripStates.instance.states[_state].unassignSegment(_begin);
        foreach (i, configSegment; DataDir.sharedConfig.states[_state].segments)
            if (configSegment.begin == _begin)
            {
                DataDir.instance.config.states[_state].segments.remove(i);
                break;
            }
        DataDir.instance.saveConfig;
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
    void post(Script script)
    {
        try
        {
            Scripts.instance.createScript(
                script.name,
                script.fileName,
                script.ledCount,
                script.autoStart,
            );
        }
        catch (ScriptsException e)
            throw new HTTPStatusException(HTTPStatus.conflict, e.msg, __FILE__, __LINE__, e);
        catch (ScriptException e)
            throw new HTTPStatusException(HTTPStatus.conflict, e.msg, __FILE__, __LINE__, e);
        DataDir.instance.config.scripts[script.name] = ConfigScript(
            script.fileName,
            script.ledCount,
            script.autoStart,
        );
        DataDir.instance.saveConfig;
    }

    override
    Script get(string _name)
    {
        enforceHTTP(_name in Scripts.constInstance.scripts, HTTPStatus.notFound, "No such script");
        const RealScript realScript = Scripts.constInstance.scripts[_name];
        return Script(
            realScript.name,
            realScript.fileName,
            realScript.ledCount,
            realScript.autoStart,
        );
    }

    override
    void delete_(string _name)
    {
        try
            Scripts.instance.removeScript(_name);
        catch (ScriptsException e)
            throw new HTTPStatusException(HTTPStatus.notFound, e.msg, __FILE__, __LINE__, e);
        DataDir.instance.config.scripts.remove(_name);
        DataDir.instance.saveConfig;
    }

    override
    bool getRunning(string _name)
    {
        enforceHTTP(_name in Scripts.constInstance.scripts, HTTPStatus.notFound, "No such script");
        return Scripts.constInstance.scripts[_name].running;
    }

    override
    void postStart(string _name)
    {
        try
            Scripts.instance.startScript(_name);
        catch (ScriptsException e)
            throw new HTTPStatusException(HTTPStatus.conflict, e.msg, __FILE__, __LINE__, e);
    }

    override
    void postStop(string _name)
    {
        try
            Scripts.instance.stopScript(_name);
        catch (ScriptsException e)
            throw new HTTPStatusException(HTTPStatus.conflict, e.msg, __FILE__, __LINE__, e);
    }

    override
    void postReload(string _name)
    {
        try
            Scripts.instance.reloadScript(_name);
        catch (ScriptsException e)
            throw new HTTPStatusException(HTTPStatus.conflict, e.msg, __FILE__, __LINE__, e);
    }
}

class SourceFileApiImpl : SourceFileApi
{
    override
    string[] get()
        => DataDir.constInstance.listScripts;

    override
    void post(SourceFile sourceFile)
    {
        DataDir.constInstance.saveScript(sourceFile.name, sourceFile.sourceCode);
    }

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

    override
    void put(string _name, string sourceCode)
    {
        DataDir.constInstance.saveScript(_name, sourceCode);
    }

    override
    void delete_(string _name)
    {
        DataDir.constInstance.deleteScript(_name);
    }
}
