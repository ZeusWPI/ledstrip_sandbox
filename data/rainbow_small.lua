Step = 1
Rainbows = 1
FramesToWait = 2
State = "default"

MaxBrightness = 0
R, G, B = {}, {}, {}
function BuildColorPalette()
    if MaxBrightness == led.maxBrightness() then return end
    log("Rebuilding")
    MaxBrightness = led.maxBrightness()
    R, G, B = {}, {}, {}
    for i = 0, led.count - 1 do
        local hue = i / led.count * 360
        local c = led.maxBrightness()
        local x = c * (1 - math.abs((hue / 60) % 2 - 1))
        local r, g, b
        if hue < 60 then      r, g, b = c, x, 0
        elseif hue < 120 then r, g, b = x, c, 0
        elseif hue < 180 then r, g, b = 0, c, x
        elseif hue < 240 then r, g, b = 0, x, c
        elseif hue < 300 then r, g, b = x, 0, c
        else                  r, g, b = c, 0, x
        end
        table.insert(R, i, r)
        table.insert(G, i, g / 4)
        table.insert(B, i, b / 4)
    end
end
while true do
    for offset = 0, led.count - 1, Step do
        if state.activeName() == State then
            BuildColorPalette()
            local ci = offset
            for i = 0, led.count - 1 do
                led.set(i, R[ci], G[ci], B[ci])
                ci = ci + Rainbows < led.count and ci + Rainbows or 0
            end
        end
        time.waitFrames(FramesToWait)
    end
end
