module util;

import data_dir : DataDir;

import core.thread : Thread;

@safe:

pure nothrow @nogc
bool inRange(T1, T2, T3)(T1 val, T2 lower, T3 upper)
    => lower <= val && val < upper;

@trusted
void sleepFrameFraction(uint fraction)
{
    Thread.sleep(DataDir.sharedConfig.frameTime / fraction);
}
