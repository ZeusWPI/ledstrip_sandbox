assert(led.count == 60, "This script must have exactly 60 leds assigned")
    
led.setAll(4, 0, 0)
while true do
    local msg = mailbox.consume("cammie")
    if #msg > 0 then
        local watchers = math.min(tonumber(msg), led.count)
        led.setSlice(0, led.count - watchers, 0, 0, 0)
        led.setSlice(led.count - watchers, led.count, 0x80, 0x80, 0)
    else
        time.sleepMsecs(100)
    end
end