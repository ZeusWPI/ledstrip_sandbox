while true do
    time.waitActiveState()
    led.setAll(0xFF, 0xFF, 0xFF)
    time.waitFrames(1)
    led.setAll(0, 0, 0)
    led.setActiveState("default")
end