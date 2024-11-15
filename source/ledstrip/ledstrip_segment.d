module ledstrip.ledstrip_segment;

import ledstrip.led : Led;
import script.script_instance : isValidScriptInstanceName;
import util : inRange;

import std.exception : basicExceptionCtors, enforce;
import std.format : f = format;
import vibe.core.log;

@safe:

shared synchronized final
class LedstripSegment
{
    private uint m_begin;
    private uint m_end;
    private string m_scriptInstanceName;

    this(uint begin, uint end, string scriptInstanceName, uint totalLedCount)
    {
        m_begin = begin;
        m_end = end;
        m_scriptInstanceName = scriptInstanceName;
        enforceIsValid(totalLedCount);
    }

    pure nothrow @nogc
    uint begin() const
        => m_begin;

    pure nothrow @nogc
    uint end() const
        => m_end;

    pure nothrow @nogc
    uint ledCount() const
        => m_end - m_begin;

    pure nothrow @nogc
    string scriptInstanceName() const
        => m_scriptInstanceName;

    pure
    void enforceIsValid(uint totalLedCount) const
    {
        alias enf = enforce!LedstripSegmentException;
        enf(m_end > m_begin, "Invalid segment: end <= begin");
        enf(totalLedCount >= m_end, "Invalid segment: totalLedCount < end");
        enf(m_scriptInstanceName.isValidScriptInstanceName, "Invalid segment: invalid script instance name");
    }

    pure nothrow @nogc
    bool overlapsWith(in LedstripSegment other) const
        => begin.inRange(other.begin, other.end) || end.inRange(other.begin + 1, other.end);
}

class LedstripSegmentException : Exception
{
    mixin basicExceptionCtors;
}
