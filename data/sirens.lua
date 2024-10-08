while true do
    while not state.activeContainsThisScript() do
        time.waitFrames(1)
    end
    for i=0, 120 do
        for j=0, led.count - 1 do
            sin_sample = math.sin(i / 4)
            if ((i + j) % 6) < 3 then
                led.set(j, 0xFF * math.abs(sin_sample), 0, 0)
            else
                led.set(j, 0, 0, 0xFF * math.abs(-sin_sample))
            end
        end
        time.waitFrames(1)
    end
    state.setDefaultActive()
end
