module ledstrip.led;

import bindbc.rpi_ws281x.rpi_ws281x : ws2811_led_t;

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
}
