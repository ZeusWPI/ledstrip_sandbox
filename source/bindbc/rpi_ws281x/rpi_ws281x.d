module bindbc.rpi_ws281x.rpi_ws281x;
//dfmt off

import bindbc.rpi_ws281x.pwm : RPI_PWM_CHANNELS;
import bindbc.rpi_ws281x.rpihw : rpi_hw_t;

@safe nothrow @nogc extern (C):

enum int WS2811_TARGET_FREQ = 800_000; // Can go as low as 400_000

// 4 color R, G, B and W ordering
enum uint SK6812_STRIP_RGBW  = 0x18100800;
enum uint SK6812_STRIP_RBGW  = 0x18100008;
enum uint SK6812_STRIP_GRBW  = 0x18081000;
enum uint SK6812_STRIP_GBRW  = 0x18080010;
enum uint SK6812_STRIP_BRGW  = 0x18001008;
enum uint SK6812_STRIP_BGRW  = 0x18000810;
enum uint SK6812_SHIFT_WMASK = 0xf0000000;

// 3 color R, G and B ordering
enum uint WS2811_STRIP_RGB = 0x00100800;
enum uint WS2811_STRIP_RBG = 0x00100008;
enum uint WS2811_STRIP_GRB = 0x00081000;
enum uint WS2811_STRIP_GBR = 0x00080010;
enum uint WS2811_STRIP_BRG = 0x00001008;
enum uint WS2811_STRIP_BGR = 0x00000810;

// predefined fixed LED types
enum uint WS2812_STRIP  = WS2811_STRIP_GRB;
enum uint SK6812_STRIP  = WS2811_STRIP_GRB;
enum uint SK6812W_STRIP = SK6812_STRIP_GRBW;

struct ws2811_t // @suppress(dscanner.style.phobos_naming_convention)
{
    ulong render_wait_time;  /// time in µs before the next render can run
    ws2811_device* device;   /// Private data for driver use
    const(rpi_hw_t)* rpi_hw; /// RPI Hardware Information
    uint freq;               /// Required output frequency
    int dmanum;              /// DMA number _not_ already in use
    ws2811_channel_t[RPI_PWM_CHANNELS] channel;
}

alias ws2811_device = void;

struct ws2811_channel_t // @suppress(dscanner.style.phobos_naming_convention)
{
    int gpionum;        /// GPIO Pin with PWM alternate function, 0 if unused
    int invert;         /// Invert output signal
    int count;          /// Number of LEDs, 0 if channel is unused
    int strip_type;     /// Strip color layout -- one of WS2811_STRIP_xxx constants
    ws2811_led_t* leds; /// LED buffers, allocated by driver based on count
    ubyte brightness;   /// Brightness value between 0 and 255
    ubyte wshift;       /// White shift value
    ubyte rshift;       /// Red shift value
    ubyte gshift;       /// Green shift value
    ubyte bshift;       /// Blue shift value
    ubyte* gamma;       /// Gamma correction table
}

alias ws2811_led_t = uint; /// 0xWWRRGGBB

enum ws2811_return_t // @suppress(dscanner.style.phobos_naming_convention)
{
    WS2811_SUCCESS                = 0,
    WS2811_ERROR_GENERIC          = -1,
    WS2811_ERROR_OUT_OF_MEMORY    = -2,
    WS2811_ERROR_HW_NOT_SUPPORTED = -3,
    WS2811_ERROR_MEM_LOCK         = -4,
    WS2811_ERROR_MMAP             = -5,
    WS2811_ERROR_MAP_REGISTERS    = -6,
    WS2811_ERROR_GPIO_INIT        = -7,
    WS2811_ERROR_PWM_SETUP        = -8,
    WS2811_ERROR_MAILBOX_DEVICE   = -9,
    WS2811_ERROR_DMA              = -10,
    WS2811_ERROR_ILLEGAL_GPIO     = -11,
    WS2811_ERROR_PCM_SETUP        = -12,
    WS2811_ERROR_SPI_SETUP        = -13,
    WS2811_ERROR_SPI_TRANSFER     = -14,
    WS2811_RETURN_STATE_COUNT
}

/// Initialize buffers/hardware
ws2811_return_t ws2811_init(ws2811_t* ws2811);

/// Tear it all down
void ws2811_fini(ws2811_t* ws2811);

/// Send LEDs off to hardware
ws2811_return_t ws2811_render(ws2811_t* ws2811);

/// Wait for DMA completion
ws2811_return_t ws2811_wait(ws2811_t* ws2811);

/// Get string representation of the given return state
const(char)* ws2811_get_return_t_str(const ws2811_return_t state);

/// Set a custom Gamma correction array based on a gamma correction factor
void ws2811_set_custom_gamma_factor(ws2811_t* ws2811, double gamma_factor);

version (Ws2811Stubs)
{
    ws2811_return_t ws2811_init(ws2811_t* ws2811) => ws2811_return_t.WS2811_SUCCESS;
    void ws2811_fini(ws2811_t* ws2811) {}
    ws2811_return_t ws2811_render(ws2811_t* ws2811) => ws2811_return_t.WS2811_SUCCESS;
    ws2811_return_t ws2811_wait(ws2811_t* ws2811) => ws2811_return_t.WS2811_SUCCESS;
    const(char)* ws2811_get_return_t_str(const ws2811_return_t state) => "";
    void ws2811_set_custom_gamma_factor(ws2811_t* ws2811, double gamma_factor) {}
}
