module ct_config;

import bindbc.rpi_ws281x.rpi_ws281x : WS2811_TARGET_FREQ, WS2812_STRIP;

enum uint ct_targetFreq = WS2811_TARGET_FREQ;
enum uint ct_ledStripType = WS2812_STRIP;
