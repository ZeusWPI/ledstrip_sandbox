module ledstrip.led;

import bindbc.rpi_ws281x.rpi_ws281x : ws2811_led_t;

import std.algorithm : min;

@safe nothrow @nogc:

struct Led
{
pure nothrow @nogc:
    version (BigEndian)
        ubyte w, r, g, b;
    else
        ubyte b, g, r, w;

    static assert(typeof(this).sizeof == ws2811_led_t.sizeof);

    this(ubyte r, ubyte g, ubyte b, ubyte w = 0)
    {
        this.r = r;
        this.g = g;
        this.b = b;
        this.w = w;
    }

    typeof(this) limitBrightness(ubyte maxBrightness) const shared
    {
        return typeof(this)(
            min(r, maxBrightness),
            min(g, maxBrightness),
            min(b, maxBrightness),
            min(w, maxBrightness),
        );
    }
}
