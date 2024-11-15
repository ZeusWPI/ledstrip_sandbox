module ledstrip.ledstrip_states;

import data_dir : DataDir;
import ledstrip.ledstrip_state : LedstripState;
import singleton : sharedSingleton;

import std.exception : basicExceptionCtors, enforce;
import std.format : f = format;
import vibe.core.log;

@safe:

final shared
class LedstripStates
{
    mixin sharedSingleton;

    private alias enf = enforce!LedstripStatesException;
    private enum string ct_defaultStateName = "default";

    private uint m_ledCount;
    private LedstripState[string] m_states;
    private LedstripState m_activeState;
    private void delegate() shared nothrow @safe m_onActiveStateChange;

    @disable this(ref typeof(this));

    private synchronized
    this()
    {
        m_ledCount = DataDir.sharedConfig.ledCount;

        enf(m_ledCount > 0, "LedstripStates: ledCount cannot be 0");

        loadConfigStates;
        setDefaultActive;
    }

    private
    void loadConfigStates()
    {
        const configStates = DataDir.sharedConfig.states;
        foreach (stateName, configState; configStates)
        {
            LedstripState state = addState(stateName);
            foreach (configSegment; configState.segments)
            {
                state.assignSegment(
                    configSegment.begin,
                    configSegment.end,
                    configSegment.scriptInstanceName,
                );
            }
        }
    }

    pure nothrow @nogc
    uint ledCount() const
        => m_ledCount;

    pure nothrow @nogc
    inout(shared(LedstripState[string])) states() inout
        => m_states;

    synchronized pure
    LedstripState addState(string stateName)
    {
        enforceIsValidState(stateName);
        enf(stateName !in m_states, f!`addState: State "%s" already exists`(stateName));
        return m_states[stateName] = new LedstripState(stateName, m_ledCount);
    }

    synchronized
    void removeState(string stateName)
    {
        enforceIsValidState(stateName);
        enf(stateName in m_states, f!`removeState: No such state "%s"`(stateName));
        foreach (k, v; m_states[stateName].segments)
            enf(false, "removeState: State still has segments assigned");
        if (activeState is m_states[stateName])
            setDefaultActive;
        m_states.remove(stateName);
    }

    pure nothrow @nogc
    inout(LedstripState) activeState() inout
        => m_activeState;

    void setActiveState(string stateName)
    {
        enf(stateName in m_states, f!`setActiveState: Unknown state "%s"`(stateName));
        m_activeState = m_states[stateName];
        if (m_onActiveStateChange)
            m_onActiveStateChange();
    }

    void setDefaultActive()
    {
        if (ct_defaultStateName !in states)
            addState(ct_defaultStateName);
        setActiveState(ct_defaultStateName);
    }

    pure nothrow @nogc
    void setOnActiveStateChange(shared void delegate() shared nothrow @safe onActiveStateChange)
    {
        m_onActiveStateChange = onActiveStateChange;
    }

    static pure
    void enforceIsValidState(string state)
    {
        enf(state.length, f!`Invalid state "%s"`(state));
    }
}

class LedstripStatesException : Exception
{
    mixin basicExceptionCtors;
}
