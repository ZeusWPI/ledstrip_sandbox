while true do
    while not state.activeContainsThisScript() do
        time.waitFrames(1)
    end
    led.setAll(0x80, 0x80, 0x80)
    time.waitFrames(2)
    led.setAll(0, 0, 0)
    state.setDefaultActive()
end
