module ledstrip.led_positions;

@safe nothrow:

struct LedPositions
{
    LedPosition[] leds;
    Label[] labels;
}

struct LedPosition
{
    int x, y;
}

struct Label
{
    string text;
    int x, y;
}

LedPositions getKelderLedPositions()
{
    LedPositions ret;
    int x;
    int y = 12;

    // Gap
    ret.labels ~= Label("Koelkast", x, y);
    x += 1;

    // Horizontal segment
    foreach (i; 0 .. 90)
    {
        ret.leds ~= LedPosition(x, y);
        x += 1;
    }

    // Gap
    x += 1;

    // Vertical segment
    foreach (i; 0 .. 12)
    {
        ret.leds ~= LedPosition(x, y);
        y -= 1;
    }
    y += 1;
    ret.labels ~= Label("Hoek keuken", x, y);
    x += 1;

    // Gap
    x += 1;

    // Horizontal segment
    foreach (i; 0 .. 157)
    {
        ret.leds ~= LedPosition(x, y);
        x += 1;
    }

    // Gap
    ret.labels ~= Label("Hoek kasten", x, y);
    x += 1;

    // Horizontal segment
    foreach (i; 0 .. 168)
    {
        ret.leds ~= LedPosition(x, y);
        x += 1;
    }

    // Gap
    ret.labels ~= Label("Hoek deur", x, y);
    x += 1;

    // Horizontal segment
    foreach (i; 0 .. 157)
    {
        ret.leds ~= LedPosition(x, y);
        x += 1;
    }

    // Gap
    x += 1;

    // Vertical segment
    ret.labels ~= Label("Hoek zetel", x, y);
    foreach (i; 0 .. 14)
    {
        ret.leds ~= LedPosition(x, y);
        y += 1;
    }
    y -= 1;
    x += 1;
    
    // Gap
    x += 1;

    // Horizontal segment
    foreach (i; 0 .. 92)
    {
        ret.leds ~= LedPosition(x, y);
        x += 1;
    }

    // Gap
    ret.labels ~= Label("Koelkast", x, y);

    return ret;
}
