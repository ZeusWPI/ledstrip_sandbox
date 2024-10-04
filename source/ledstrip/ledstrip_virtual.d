module ledstrip.ledstrip_virtual;

version (LedstripVirtual):

import ledstrip.led : Led;
import ledstrip.ledstrip_states : LedstripStates;
import ledstrip.ledstrip : Ledstrip, LedStripException;

import core.time : Duration;

import std.algorithm : map;
import std.format : f = format;

import vibe.core.log;

@safe:

shared
class LedstripVirtual : Ledstrip
{
    private Led[] m_leds;

    @disable this(ref typeof(this));

    this(LedstripStates states, Duration frameTime)
    {
        super(states, frameTime);
        m_leds = new Led[](ledCount);
    }

    protected override
    void render()
    {
        /*
        string[] ledStrings;
        foreach(i, Led led; leds)
            ledStrings ~= f!"%u:0x%02x%02x%02x"(i, led.r, led.g, led.b);
        logInfo("LedstripVirtual.render: %-(%s %)", ledStrings);
        */
    }

    override pure nothrow @nogc
    shared(Led[]) leds()
        => m_leds;
}
