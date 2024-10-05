while true do
    while not state.activeContainsThisScript() do
        time.waitFrames(1)
    end
    led.setAll(0xFF, 0xFF, 0xFF)
    time.waitFrames(2)
    led.setAll(0, 0, 0)
    led.setDefaultActive()
end
