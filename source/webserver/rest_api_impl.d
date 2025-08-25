module webserver.rest_api_impl;

import config : ConfigScriptInstance, ConfigSegment, ConfigState;
import data_dir : DataDir;
import ledstrip.led_positions : getKelderLedPositions;
import ledstrip.ledstrip : Ledstrip;
import ledstrip.ledstrip_segment : LedstripSegment;
import ledstrip.ledstrip_state : LedstripState, LedstripStateException;
import ledstrip.ledstrip_states : LedstripStates, LedstripStatesException;
import mailbox : Mailbox;
import script.script_instance : ScriptInstance, ScriptInstanceException;
import script.script_instances : ScriptInstances, ScriptInstancesException;
import thread_manager : inMainThread;
import webserver.rest_api : ConfigApi, RestApi, ScriptInstanceApi, ScriptSourceFileApi, SegmentApi, StateApi;

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
    private ScriptInstanceApiImpl m_scriptInstanceApi;
    private ScriptSourceFileApiImpl m_scriptSourceFileApi;

    invariant
    {
        assert(inMainThread);
    }

    this()
    in (inMainThread)
    {
        m_configApi = new ConfigApiImpl;
        m_stateApi = new StateApiImpl;
        m_scriptInstanceApi = new ScriptInstanceApiImpl;
        m_scriptSourceFileApi = new ScriptSourceFileApiImpl;
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
    Collection!ScriptInstanceApi scriptInstances()
        => Collection!ScriptInstanceApi(m_scriptInstanceApi);

    override
    Collection!ScriptSourceFileApi scriptSourceFiles()
        => Collection!ScriptSourceFileApi(m_scriptSourceFileApi);

    override
    void putMailbox(string topic, string message)
    {
        Mailbox.instance.put(topic, message);
    }

    override
    Json getLedPositions()
        => getKelderLedPositions.serializeToJson;
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
    SegmentPod[] get(string _state)
    {
        const LedstripStates states = LedstripStates.constInstance;
        enforceHTTP(_state in states.states, HTTPStatus.notFound, "No such state");
        const LedstripState state = states.states[_state];
        SegmentPod[] arr;
        foreach (const LedstripSegment seg; state.segments)
            arr ~= SegmentPod(seg.begin, seg.end, seg.scriptInstanceName);
        return arr;
    }

    override
    void post(string _state, SegmentPod segment)
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
                segment.scriptInstanceName,
            );
        }
        catch (LedstripStatesException e)
            throw new HTTPStatusException(HTTPStatus.conflict, e.msg, __FILE__, __LINE__, e);
        catch (LedstripStateException e)
            throw new HTTPStatusException(HTTPStatus.conflict, e.msg, __FILE__, __LINE__, e);
        DataDir.instance.config.states[_state].segments ~= ConfigSegment(
            segment.begin,
            segment.end,
            segment.scriptInstanceName,
        );
        DataDir.instance.saveConfig;
    }

    override
    SegmentPod get(string _state, uint _begin)
    {
        const LedstripStates states = LedstripStates.constInstance;
        enforceHTTP(_state in states.states, HTTPStatus.notFound, "No such state");
        const LedstripState state = states.states[_state];
        enforceHTTP(_begin in state.segments, HTTPStatus.notFound, "No segment with provided begin led");
        const LedstripSegment seg = state.segments[_begin];
        return SegmentPod(seg.begin, seg.end, seg.scriptInstanceName);
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
                DataDir.instance.config.states[_state].segments
                    = DataDir.instance.config.states[_state].segments.remove(i);
                break;
            }
        DataDir.instance.saveConfig;
    }
}

class ScriptInstanceApiImpl : ScriptInstanceApi
{
    override
    string[] get()
    {
        string[] names;
        foreach (name, scriptInstance; ScriptInstances.constInstance.scriptInstances)
            names ~= name;
        return names;
    }

    override
    void post(ScriptInstancePod scriptInstance)
    {
        try
        {
            ScriptInstances.instance.createScriptInstance(
                scriptInstance.name,
                scriptInstance.sourceFileName,
                scriptInstance.ledCount,
                scriptInstance.autoStart,
            );
        }
        catch (ScriptInstancesException e)
            throw new HTTPStatusException(HTTPStatus.conflict, e.msg, __FILE__, __LINE__, e);
        catch (ScriptInstanceException e)
            throw new HTTPStatusException(HTTPStatus.conflict, e.msg, __FILE__, __LINE__, e);
        DataDir.instance.config.scriptInstances[scriptInstance.name] = ConfigScriptInstance(
            scriptInstance.sourceFileName,
            scriptInstance.ledCount,
            scriptInstance.autoStart,
        );
        DataDir.instance.saveConfig;
    }

    override
    ScriptInstancePod get(string _name)
    {
        enforceHTTP(
            _name in ScriptInstances.constInstance.scriptInstances,
            HTTPStatus.notFound,
            "No such script instance",
        );
        const ScriptInstance scriptInstance = ScriptInstances.constInstance.scriptInstances[_name];
        return ScriptInstancePod(
            scriptInstance.name,
            scriptInstance.sourceFileName,
            scriptInstance.ledCount,
            scriptInstance.autoStart,
        );
    }

    override
    void delete_(string _name)
    {
        try
            ScriptInstances.instance.removeScriptInstance(_name);
        catch (ScriptInstancesException e)
            throw new HTTPStatusException(HTTPStatus.notFound, e.msg, __FILE__, __LINE__, e);
        DataDir.instance.config.scriptInstances.remove(_name);
        DataDir.instance.saveConfig;
    }

    override
    bool getRunning(string _name)
    {
        enforceHTTP(
            _name in ScriptInstances.constInstance.scriptInstances,
            HTTPStatus.notFound,
            "No such script instance",
        );
        return ScriptInstances.constInstance.scriptInstances[_name].running;
    }

    override
    void postStart(string _name)
    {
        try
            ScriptInstances.instance.startScriptInstance(_name);
        catch (ScriptInstancesException e)
            throw new HTTPStatusException(HTTPStatus.conflict, e.msg, __FILE__, __LINE__, e);
    }

    override
    void postStop(string _name)
    {
        try
            ScriptInstances.instance.stopScriptInstance(_name);
        catch (ScriptInstancesException e)
            throw new HTTPStatusException(HTTPStatus.conflict, e.msg, __FILE__, __LINE__, e);
    }

    override
    void postReload(string _name)
    {
        try
            ScriptInstances.instance.reloadScriptInstance(_name);
        catch (ScriptInstancesException e)
            throw new HTTPStatusException(HTTPStatus.conflict, e.msg, __FILE__, __LINE__, e);
    }
}

class ScriptSourceFileApiImpl : ScriptSourceFileApi
{
    override
    string[] get()
        => DataDir.constInstance.listScriptSourceFiles;

    override
    void post(ScriptSourceFilePod scriptSourceFile)
    {
        DataDir.constInstance.saveScriptSourceFile(
            scriptSourceFile.name,
            scriptSourceFile.sourceCode,
        );
    }

    override
    ScriptSourceFilePod get(string _name)
    {
        string sourceCode;
        try
        {
            sourceCode = DataDir.constInstance.loadScriptSourceFile(_name);
        }
        catch (Exception e)
        {
            throw new HTTPStatusException(
                HTTPStatus.notFound,
                f!`Can't load script source file "%s": %s`(_name, e.msg),
            );
        }

        return ScriptSourceFilePod(_name, sourceCode);
    }

    override
    void put(string _name, string sourceCode)
    {
        DataDir.constInstance.saveScriptSourceFile(_name, sourceCode);
    }

    override
    void delete_(string _name)
    {
        DataDir.constInstance.deleteScriptSourceFile(_name);
    }
}
