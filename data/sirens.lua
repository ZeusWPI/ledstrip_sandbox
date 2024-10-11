while true do
    while not state.activeContainsThisScript() do
        time.waitFrames(1)
    end
    for i=0, 120 do
        sin_sample = math.sin(i / 2)
        if sin_sample >= 0 then
            led.setAll(0x40 * sin_sample, 0, 0)
        else
            led.setAll(0, 0, 0x40 * -sin_sample)
        end
        time.waitFrames(1)
    end
    state.setDefaultActive()
end
