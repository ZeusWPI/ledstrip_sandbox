module ledstrip.led_assignments;
// dfmt off

import ledstrip.led : Led;
import script.script : Script;
import util : inRange;

import std.algorithm.mutation : remove;
import std.exception : basicExceptionCtors, enforce;
import std.format : f = format;
import vibe.core.log;

@safe:

final
class LedAssignments
{
    private size_t m_ledCount;
    private Segment[][string] m_states;
    private string m_state;

    @disable this(ref typeof(this));

    pure nothrow
    this(size_t ledCount)
    in (ledCount > 0)
    {
        m_ledCount = ledCount;
        setState("default");
    }

    pure nothrow @nogc
    size_t ledCount() const
        => m_ledCount;

    pure nothrow @nogc
    string state() const
        => m_state;
    
    pure nothrow
    void setState(string state)
    in (state.length)
    {
        m_state = state;
        if (m_state !in m_states)
            m_states[m_state] = [];
    }

    pure nothrow
    ref inout(Segment[]) currSegments() inout
    in (m_state in m_states)
        => m_states[m_state];
    
    void assign(string state, size_t begin, size_t end, Script script)
    {
        if (state !in m_states)
            m_states[state] = [];
        
        Segment toAssign = Segment(begin, end, script);
        toAssign.enforceIsValid(ledCount);

        foreach (i, seg; m_states[state])
            if (seg.overlapsWith(toAssign))
            {
                enum string fmt = "Failed to assign: new segment %s overlaps with existing segment %s";
                throw new Exception(f!fmt(toAssign, seg));
            }

        currSegments ~= toAssign;
    }

    void unassign(string state, size_t begin, size_t end)
    {
        enforce!LedAssignmentsException(
            state in m_states,
            f!"Failed to unassign: unknown state %s"(state),
        );

        Segment toUnassign = Segment(begin, end);
        toUnassign.enforceIsValid(ledCount, /*ignoreScript:*/ true);

        foreach (i, seg; m_states[state])
            if (seg.begin == toUnassign.begin && seg.end == toUnassign.end)
            {
                currSegments.remove(i);
                return;
            }
        assert(false, f!"Failed to unassign: no such segment %s"(toUnassign));
    }
}

shared
struct Segment
{
    size_t begin, end;
    Script script;

    pure
    void enforceIsValid(size_t ledCount, bool ignoreScript = false) const
    {
        if (end <= begin)
        {
            throw new LedAssignmentsException("Invalid segment due to end <= begin");
        }
        if (ledCount < end)
        {
            throw new LedAssignmentsException("Invalid segment due to ledCount < end");
        }
        if (!ignoreScript && script is null)
        {
            throw new LedAssignmentsException("Invalid segment due to script is null");
        }
        if (!ignoreScript && script.leds.length != end - begin)
        {
            throw new LedAssignmentsException("Invalid segment due to script.leds.length != end - begin");
        }
    }

    pure nothrow @nogc
    bool overlapsWith(in Segment other) const
        => begin.inRange(other.begin, other.end) || end.inRange(other.begin + 1, other.end);

    string toString() const
        => f!"(begin=%u, end=%u)"(begin, end);
}

class LedAssignmentsException : Exception
{
    mixin basicExceptionCtors;
}
