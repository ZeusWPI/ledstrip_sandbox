while true do
    while not state.activeContainsThisScript() do
        time.waitFrames(1)
    end
    brights = {0, 10, 50, 200, 255}
    for j=1,5 do
        for i=1, 5 do
        led.setAll(brights[i], 0, 0)
            time.waitFrames(1)
        end
    end
    led.setAll(0, 0, 0)
    state.setDefaultActive()
end
