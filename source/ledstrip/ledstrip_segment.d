module ledstrip.ledstrip_segment;

import ledstrip.led : Led;
import script.script : Script;
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
    private Script m_script;

    this(uint begin, uint end, Script script, uint totalLedCount)
    {
        m_begin = begin;
        m_end = end;
        m_script = script;
        enforceIsValid(totalLedCount);
    }

    pure nothrow @nogc
    uint begin() const
        => m_begin;

    pure nothrow @nogc
    uint end() const
        => m_end;

    pure nothrow @nogc
    inout(Script) script() inout
        => m_script;

    pure
    void enforceIsValid(uint totalLedCount) const
    {
        alias enf = enforce!LedstripSegmentException;
        enf(end > begin, "Invalid segment: end <= begin");
        enf(totalLedCount >= end, "Invalid segment: totalLedCount < end");
        enf(script !is null, "Invalid segment: script is null");
        enf(script.leds.length == end - begin, "Invalid segment: script.leds.length != end - begin");
    }

    pure nothrow @nogc
    bool overlapsWith(in LedstripSegment other) const
        => begin.inRange(other.begin, other.end) || end.inRange(other.begin + 1, other.end);

    string toString() const
        => f!`LedstripSegment(begin=%u, end=%u, script="%s")`(begin, end, /*script.uuid*/ "someuuid");
}

class LedstripSegmentException : Exception
{
    mixin basicExceptionCtors;
}
