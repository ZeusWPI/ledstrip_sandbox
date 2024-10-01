module bindbc.rpi_ws281x.rpihw;
//dfmt off

@safe nothrow @nogc extern (C):

enum uint RPI_HWVER_TYPE_UNKNOWN = 0;
enum uint RPI_HWVER_TYPE_PI1     = 1;
enum uint RPI_HWVER_TYPE_PI2     = 2;
enum uint RPI_HWVER_TYPE_PI4     = 3;

struct rpi_hw_t // @suppress(dscanner.style.phobos_naming_convention)
{
    uint type;
    uint hwver;
    uint periph_base;
    uint videocore_base;
    char* desc;
}

const(rpi_hw_t)* Api_hw_detect(); // @suppress(dscanner.style.phobos_naming_convention)

version (Ws2811Stubs)
{
    const(rpi_hw_t)* Api_hw_detect() => null;
}

