module ledstrip.ledstrip_virtual;

version (LedstripVirtual)  :  //

import ledstrip.led : Led;
import ledstrip.ledstrip : Ledstrip;
import thread_manager : inThreadKind, ThreadKind;

@safe:
package:

final shared
class LedstripVirtual : Ledstrip
{
    private Led[] m_leds;

    package synchronized
    this()
    in (inThreadKind(ThreadKind.main))
    {
        super();
        m_leds = new Led[](ledCount);
    }

    protected override synchronized
    void render()
    in (inThreadKind(ThreadKind.renderer))
    {
    }

    override synchronized pure nothrow @nogc
    shared(Led[]) leds()
        => m_leds;
}
