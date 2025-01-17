assert(led.count == 60, "This script must have exactly 60 leds assigned")

mailbox.subscribe("cammie")

led.setAll(4, 0, 0)

local lastWatcherCount = 0
while true do
    local msg = mailbox.consume("cammie")
    if #msg == 0 then
        time.sleepMsecs(100)
    else
        local watcherCount = math.min(tonumber(msg) or 0, led.count)

        if watcherCount > 0 and lastWatcherCount == 0 then
            --state.setActiveByName("alarm")
        end

        led.setSlice(0, led.count - watcherCount, 0, 0, 0)
        led.setSlice(led.count - watcherCount, led.count, 0x80, 0x80, 0)

        lastWatcherCount = watcherCount
    end
end
