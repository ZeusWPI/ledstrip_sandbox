assert(led.count == 32, "This script must have exactly 32 leds assigned")

colors = {{255, 0, 0}, {255, 255, 0}, {0, 255, 0}, {0, 0, 255}, {148, 0, 211}}
color_change_delay = bit.lshift(1, 8)
brightness = 16
while true do
    local now = time.unixTimeSeconds()
    local color_i = (math.floor(now / color_change_delay) * color_change_delay % 5) + 1
    local color = colors[color_i]
    for i = 0, led.count - 1 do
        led_i = led.count - 1 - i
        if bit.band(bit.rshift(now, i), 1) == 1 then
            led.set(led_i,
                color[1] / brightness,
                color[2] / brightness,
                color[3] / brightness
            )
        else
            led.set(led_i, 0, 0, 0)
        end
    end
    time.sleepMsecs(100)
end
