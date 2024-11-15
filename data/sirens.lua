while true do
    while not state.activeContainsThisScriptInstance() do
        time.waitFrames(1)
    end
    for i=0, 120 do
        i_mod = (i % 12);
        if i_mod < 4 then
            led.setAll(0xFF, 0, 0)
        elseif i_mod < 6 then
            led.setAll(0, 0, 0)
        elseif i_mod < 10 then
            led.setAll(0, 0, 0xFF)
        else
            led.setAll(0, 0, 0)
        end
        time.waitFrames(1)
    end
    state.setDefaultActive()
end
