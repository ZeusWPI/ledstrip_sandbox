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
    void addState(string state)
    {
        enforceIsValidState(state);
        enf(state !in m_states, f!`addState: State "%s" already exists`(state));
        m_states[state] = new LedstripState(state, m_ledCount);
    }

    pure nothrow @nogc
    inout(LedstripState) activeState() inout
        => m_activeState;

    void setActiveState(string state)
    {
        enf(state in m_states, f!`setActiveState: Unknown state "%s"`(state));
        m_activeState = m_states[state];
        if (m_onActiveStateChange)
            m_onActiveStateChange();
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
