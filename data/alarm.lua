while true do
    while not state.activeContainsThisScriptInstance() do
        time.waitFrames(1)
    end
    for i=0,0 do
        for j=0,30,2 do
            led.setAll(j, j==0 and 0 or (j>8 and j/8 or 1), 0)
            time.waitFrames(1)
        end
    end
    led.setAll(0, 0, 0)
    state.setDefaultActive()
end
