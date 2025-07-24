assert(led.count >= 68, "This script must have at least 68 leds assigned")

mailbox.subscribe("weather")

led.setAll(4, 0, 0)

local lastMessageTimestamp = time.unixTimeSeconds()
while true do
    local msg = mailbox.consume("weather")
    if #msg == 0 then
        if time.unixTimeSeconds() - lastMessageTimestamp > 120 then
            led.setAll(4, 0, 0)
        end
    else
        local i = 0
        for tuple in msg:gmatch("%(([%d, ]+)%)") do
            r, g, b = tuple:match("(%d+), (%d+), (%d+)")
            if r and g and b then
                led.set(i, tonumber(r), tonumber(g), tonumber(b))
                i = i + 1
                if i == led.count then
                    break
                end
            end
        end
        led.setSlice(i, led.count, 0, 0, 0)
        lastMessageTimestamp = time.unixTimeSeconds()
    end
end
