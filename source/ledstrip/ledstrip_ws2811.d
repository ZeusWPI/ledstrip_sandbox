module ledstrip.ledstrip_ws2811;

version (LedstripWs2811)  :  //

import ct_config : ct_ledStripType, ct_targetFreq;
import data_dir : DataDir;
import ledstrip.led : Led;
import ledstrip.ledstrip : Ledstrip, LedstripException;
import thread_manager : inThreadKind, ThreadKind;

import core.time : Duration;

import std.format : f = format;

import bindbc.rpi_ws281x;

@safe:
package:

shared
class LedstripWs2811 : Ledstrip
{
    private __gshared ws2811_t g_ws2811;
    private bool m_setupWs2811Done;

    @disable this(ref typeof(this));

    package synchronized
    this()
    in (inThreadKind(ThreadKind.main))
    {
        super();
        setupWs2811(
            ct_targetFreq,
            DataDir.sharedConfig.dmaNumber,
            DataDir.sharedConfig.gpioPin,
            ct_ledStripType,
        );
    }

    private synchronized @trusted
    void setupWs2811(int targetFreq, int dmaNumber, int gpioPin, uint stripType)
    in (inThreadKind(ThreadKind.main))
    in (!m_setupWs2811Done)
    out (; m_setupWs2811Done)
    {
        g_ws2811.freq = targetFreq;
        g_ws2811.dmanum = dmaNumber;

        // Enable channel 0
        g_ws2811.channel[0].gpionum = gpioPin;
        g_ws2811.channel[0].invert = 0;
        g_ws2811.channel[0].count = ledCount;
        g_ws2811.channel[0].strip_type = stripType;
        g_ws2811.channel[0].brightness = 255;

        // Disable channel 1 by setting these fields to 0 (as per the docs)
        g_ws2811.channel[1].gpionum = 0;
        g_ws2811.channel[1].invert = 0;
        g_ws2811.channel[1].count = 0;
        g_ws2811.channel[1].brightness = 0;

        ws2811_return_t initResult = ws2811_init(&g_ws2811);
        if (initResult != ws2811_return_t.WS2811_SUCCESS)
        {
            const char* reason = ws2811_get_return_t_str(initResult);
            throw new LedstripException(f!"ws2811_init failed: %s"(reason));
        }

        m_setupWs2811Done = true;
    }

    synchronized nothrow @trusted //
     ~this()
    in (inThreadKind(ThreadKind.main))
    {
        if (m_setupWs2811Done)
            ws2811_fini(&g_ws2811);
    }

    protected override synchronized @trusted
    void render()
    in (inThreadKind(ThreadKind.renderer))
    in (m_setupWs2811Done)
    {
        ws2811_render(&g_ws2811);
    }

    override synchronized nothrow @nogc @trusted
    shared(Led[]) leds()
    in (m_setupWs2811Done)
        => cast(shared(Led)[]) g_ws2811.channel[0].leds[0 .. ledCount];
}
