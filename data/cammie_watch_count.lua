mailbox.subscribe("cammie")

led.setAll(4, 0, 0)

local lastMessageTimestamp = time.unixTimeSeconds()
while true do
    local msg = mailbox.consume("cammie")
    if #msg == 0 then
        if time.unixTimeSeconds() - lastMessageTimestamp > 10 then
            led.setAll(4, 0, 0)
        end
        time.sleepMsecs(100)
    else
        local watcherCountParseResult = tonumber(msg)
        if watcherCountParseResult then
            local watcherCount = math.min(watcherCountParseResult, led.count)
            led.setSlice(0, led.count - watcherCount, 0, 0, 0)
            led.setSlice(led.count - watcherCount, led.count, 0x80, 0x80, 0)
            lastMessageTimestamp = time.unixTimeSeconds()
        end
    end
end
