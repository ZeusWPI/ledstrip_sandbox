module util;

import main : Main;
import vibe.core.core : sleep;

@safe:

pure nothrow @nogc
bool inRange(T1, T2, T3)(T1 val, T2 lower, T3 upper)
    => lower <= val && val < upper;

void sleepFrameFraction(uint fraction)
{
    sleep(Main.instance.frameTime / fraction);
}
