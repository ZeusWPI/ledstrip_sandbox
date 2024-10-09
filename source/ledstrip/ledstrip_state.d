module ledstrip.ledstrip_state;

import ledstrip.ledstrip_segment : LedstripSegment;

import std.exception : basicExceptionCtors, enforce;
import std.format : f = format;
import vibe.core.log;

@safe:

shared synchronized final
class LedstripState
{
    private alias enf = enforce!LedstripStateException;

    private string m_name;
    private uint m_totalLedCount;
    private LedstripSegment[uint] m_segments;

    pure
    this(string name, uint totalLedCount)
    {
        enf(name.length);
        enf(totalLedCount > 0);
        m_name = name;
        m_totalLedCount = totalLedCount;
    }

    pure nothrow @nogc
    string name() const
        => m_name;

    pure nothrow @nogc
    ref const(shared(LedstripSegment[uint])) segments() const
        => m_segments;

    void assignSegment(uint begin, uint end, string scriptName)
    {
        LedstripSegment segToAssign = new LedstripSegment(begin, end, scriptName, m_totalLedCount);
        foreach (k, seg; segments)
        {
            enf(
                !seg.overlapsWith(segToAssign),
                f!"Failed to assign: new segment %s overlaps with existing segment %s"(
                    segToAssign, seg,
                ),
            );
        }
        m_segments[begin] = segToAssign;
    }

    void unassignSegment(uint begin)
    {
        enf(begin in m_segments, f!`Failed to unassign: no segment with begin led "%u"`(begin));
        m_segments.remove(begin);
    }
}

class LedstripStateException : Exception
{
    mixin basicExceptionCtors;
}
