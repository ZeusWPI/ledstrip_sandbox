module ledstrip.ledstrip_ws2811;
// dfmt off
version (LedstripWs2811):

import ledstrip.led : Led;
import ledstrip.led_assignments : LedAssignments;
import ledstrip.ledstrip : Ledstrip, LedStripException;

import core.time : Duration;

import std.format : f = format;

import bindbc.rpi_ws281x;

@safe:

class LedstripWs2811 : Ledstrip
{
    private ws2811_t m_ws2811;
    private bool m_setupWs2811Done;

    @disable this(ref typeof(this));

    this(LedAssignments ledAssignments, Duration frameTime,
        int targetFreq, int dmaNumber, int gpioPin, uint stripType)
    {
        super(ledAssignments, frameTime);
        setupWs2811(targetFreq, dmaNumber, gpioPin, stripType);
    }

    nothrow
    ~this()
    {
        if (m_setupWs2811Done)
            ws2811_fini(&m_ws2811);
    }

    protected override
    void render()
    in (m_setupWs2811Done)
    {
        ws2811_render(&m_ws2811);
    }

    override pure nothrow @nogc @trusted
    Led[] leds()
    in (m_setupWs2811Done)
        => cast(Led[]) m_ws2811.channel[0].leds[0 .. ledCount];

    private
    void setupWs2811(int targetFreq, int dmaNumber, int gpioPin, uint stripType)
    in (!m_setupWs2811Done)
    out (; m_setupWs2811Done)
    {
        m_ws2811.freq = targetFreq;
        m_ws2811.dmanum = dmaNumber;

        // Enable channel 0
        m_ws2811.channel[0].gpionum = gpioPin;
        m_ws2811.channel[0].invert = 0;
        m_ws2811.channel[0].count = ledCount;
        m_ws2811.channel[0].strip_type = stripType;
        m_ws2811.channel[0].brightness = 255;

        // Disable channel 1 by setting these fields to 0 (as per the docs)
        m_ws2811.channel[1].gpionum = 0;
        m_ws2811.channel[1].invert = 0;
        m_ws2811.channel[1].count = 0;
        m_ws2811.channel[1].brightness = 0;

        ws2811_return_t initResult = ws2811_init(&m_ws2811);
        if (initResult != ws2811_return_t.WS2811_SUCCESS)
        {
            const char* reason = ws2811_get_return_t_str(initResult);
            throw new LedStripException(f!"ws2811_init failed: %s"(reason));
        }

        m_setupWs2811Done = true;
    }
}