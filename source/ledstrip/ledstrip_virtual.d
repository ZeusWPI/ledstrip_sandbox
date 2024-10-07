module ledstrip.ledstrip_virtual;

version (LedstripVirtual)  :  //

import ledstrip.led : Led;
import ledstrip.ledstrip_states : LedstripStates;
import ledstrip.ledstrip : Ledstrip, LedStripException;
import thread_manager : ThreadManager;

import core.time : Duration;

import std.algorithm : map;
import std.format : f = format;

import vibe.core.log;

@safe:
package:

final shared
class LedstripVirtual : Ledstrip
{
    private Led[] m_leds;

    @disable this(ref typeof(this));

    package synchronized
    this()
    {
        super();
        m_leds = new Led[](ledCount);
    }

    protected override
    void render()
    in (ThreadManager.constInstance.inMainThread, "LedstripVirtual: render must be called from main thread")
    {
    }

    override pure nothrow @nogc
    shared(Led[]) leds()
        => m_leds;
}
