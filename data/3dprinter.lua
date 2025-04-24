mailbox.subscribe("3dprinter")

led.setAll(0x20, 0x04, 0x00)

while true do
    local msg = mailbox.consume("3dprinter")
    if #msg == 0 then
        time.sleepMsecs(100)
    else
        local progress = tonumber(msg) or 0
        if progress < 100 then
            led.setAll(0x20, 0x00, 0x00)
            led.setSlice(0, math.floor(progress / 100 * led.count), 0x00, 0x20, 0x00)
        else
            for _ = 0, 9 do
                led.setAll(0x00, 0x40, 0x00)
                time.sleepMsecs(500)
                led.setAll(0x00, 0x00, 0x00)
                time.sleepMsecs(500)
            end
            led.setAll(0x20, 0x04, 0x00)
        end
    end
end
