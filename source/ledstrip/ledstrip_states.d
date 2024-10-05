module ledstrip.ledstrip_states;

import ledstrip.ledstrip_state : LedstripState;

import std.exception : basicExceptionCtors, enforce;
import std.format : f = format;
import vibe.core.log;

@safe:

final shared synchronized
class LedstripStates
{
    private alias enf = enforce!LedstripStatesException;
    private enum ct_defaultStateName = "default";

    private uint m_ledCount;
    private LedstripState[string] m_states;
    private LedstripState m_activeState;
    private void delegate() shared nothrow @safe m_onActiveStateChange;

    @disable this(ref typeof(this));

    pure
    this(uint ledCount)
    {
        enf(ledCount > 0);
        m_ledCount = ledCount;
    }

    pure nothrow @nogc
    uint ledCount() const
        => m_ledCount;

    pure nothrow @nogc
    inout(shared(LedstripState[string])) states() inout
        => m_states;

    pure
    LedstripState addState(string stateName)
    {
        enforceIsValidState(stateName);
        enf(stateName !in m_states, f!`addState: State "%s" already exists`(stateName));
        return m_states[stateName] = new LedstripState(stateName, m_ledCount);
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

    pure
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
