module ledstrip.ledstrip_ws2811;

version (LedstripWs2811)  :  //

import ct_config : ct_ledStripType, ct_targetFreq;
import data_dir : DataDir;
import ledstrip.led : Led;
import ledstrip.ledstrip : Ledstrip, LedStripException;
import ledstrip.ledstrip_states : LedstripStates;
import thread_manager : ThreadManager;

import core.time : Duration;

import std.format : f = format;

import bindbc.rpi_ws281x;

@safe:
package:

shared
class LedstripWs2811 : Ledstrip
{
    private __gshared ws2811_t m_ws2811;
    private bool m_setupWs2811Done;

    @disable this(ref typeof(this));

    package synchronized
    this()
    in (ThreadManager.constInstance.inMainThread, "LedstripWs2811: ctor must be called from main thread")
    {
        super();
        setupWs2811(
            ct_targetFreq,
            DataDir.sharedConfig.dmaNumber,
            DataDir.sharedConfig.gpioPin,
            ct_ledStripType,
        );
    }

    nothrow @trusted //
     ~this()
    in (ThreadManager.constInstance.inMainThread, "LedstripWs2811: dtor must be called from main thread")
    {
        if (m_setupWs2811Done)
            ws2811_fini(&m_ws2811);
    }

    protected override @trusted
    void render()
    in (ThreadManager.constInstance.inMainThread, "LedstripWs2811: render must be called from main thread")
    in (m_setupWs2811Done)
    {
        ws2811_render(&m_ws2811);
    }

    override nothrow @nogc @trusted
    shared(Led[]) leds()
    in (ThreadManager.constInstance.inMainThread, "LedstripWs2811: leds must be called from main thread")
    in (m_setupWs2811Done)
        => cast(shared(Led)[]) m_ws2811.channel[0].leds[0 .. ledCount];

    private @trusted
    void setupWs2811(int targetFreq, int dmaNumber, int gpioPin, uint stripType)
    in (ThreadManager.constInstance.inMainThread, "LedstripWs2811: setupWs2811 must be called from main thread")
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
