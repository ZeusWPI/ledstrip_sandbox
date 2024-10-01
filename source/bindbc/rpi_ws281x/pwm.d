module bindbc.rpi_ws281x.pwm;
//dfmt off

@safe nothrow @nogc extern (C):

/*
 * Pin mapping of alternate pin configuration for PWM
 *
 * GPIO | ALT PWM0 | ALT PWM1
 * -----|----------|---------
 * 12   | 0        |
 * 13   |          | 0
 * 18   | 5        |
 * 19   |          | 5
 * 40   | 0        |
 * 41   |          | 0
 * 45   |          | 0
 * 52   | 1        |
 * 53   |          | 1
 */

enum uint RPI_PWM_CHANNELS = 2;

enum RPI_PWM_CTL_MSEN2 = 1 << 15;
enum RPI_PWM_CTL_USEF2 = 1 << 13;
enum RPI_PWM_CTL_POLA2 = 1 << 12;
enum RPI_PWM_CTL_SBIT2 = 1 << 11;
enum RPI_PWM_CTL_RPTL2 = 1 << 10;
enum RPI_PWM_CTL_MODE2 = 1 << 9;
enum RPI_PWM_CTL_PWEN2 = 1 << 8;
enum RPI_PWM_CTL_MSEN1 = 1 << 7;
enum RPI_PWM_CTL_CLRF1 = 1 << 6;
enum RPI_PWM_CTL_USEF1 = 1 << 5;
enum RPI_PWM_CTL_POLA1 = 1 << 4;
enum RPI_PWM_CTL_SBIT1 = 1 << 3;
enum RPI_PWM_CTL_RPTL1 = 1 << 2;
enum RPI_PWM_CTL_MODE1 = 1 << 1;
enum RPI_PWM_CTL_PWEN1 = 1 << 0;

enum RPI_PWM_STA_STA4  = 1 << 12;
enum RPI_PWM_STA_STA3  = 1 << 11;
enum RPI_PWM_STA_STA2  = 1 << 10;
enum RPI_PWM_STA_STA1  = 1 << 9;
enum RPI_PWM_STA_BERR  = 1 << 8;
enum RPI_PWM_STA_GAP04 = 1 << 7;
enum RPI_PWM_STA_GAP03 = 1 << 6;
enum RPI_PWM_STA_GAP02 = 1 << 5;
enum RPI_PWM_STA_GAP01 = 1 << 4;
enum RPI_PWM_STA_RERR1 = 1 << 3;
enum RPI_PWM_STA_WERR1 = 1 << 2;
enum RPI_PWM_STA_EMPT1 = 1 << 1;
enum RPI_PWM_STA_FULL1 = 1 << 0;

enum RPI_PWM_DMAC_ENAB = 1 << 31;
enum RPI_PWM_DMAC_PANIC(val) = (val & 0xff) << 8;
enum RPI_PWM_DMAC_DREQ(val)  = (val & 0xff) << 0;

struct pwm_t // @suppress(dscanner.style.phobos_naming_convention)
{
align(4):
    uint ctl;
    uint sta;
    uint dmac;
    uint resvd_0x0c;
    uint rng1;
    uint dat1;
    uint fif1;
    uint resvd_0x1c;
    uint rng2;
    uint dat2;
}

enum uint PWM_OFFSET      = 0x0020c000;
enum uint PWM_PERIPH_PHYS = 0x7e20c000;

struct pwm_pin_table_t // @suppress(dscanner.style.phobos_naming_convention)
{
    int pinnum;
    int altnum;
}

struct pwm_pin_tables_t // @suppress(dscanner.style.phobos_naming_convention)
{
    const int count;
    const pwm_pin_table_t *pins;
} 

int pwm_pin_alt(int chan, int pinnum);

version (Ws2811Stubs)
{
    int pwm_pin_alt(int chan, int pinnum) => 0;
}

