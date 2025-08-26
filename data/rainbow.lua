while true do
    for offset = 0, led.count - 1 do
        for i = 0, led.count - 1 do
            local hue = (offset + i) % led.count / led.count * 360
            local c = 255 / 4
            local x = c * (1 - math.abs((hue / 60) % 2 - 1))
            local r, g, b
            if hue < 60 then      r, g, b = c, x, 0
            elseif hue < 120 then r, g, b = x, c, 0
            elseif hue < 180 then r, g, b = 0, c, x
            elseif hue < 240 then r, g, b = 0, x, c
            elseif hue < 300 then r, g, b = x, 0, c
            else                  r, g, b = c, 0, x
            end
            led.set(i, r, g, b)
        end
        time.waitFrames(1)
    end
end
