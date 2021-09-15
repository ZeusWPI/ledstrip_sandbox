print("hello world")
led(1, 255, 255, 3)
print("There are " .. tostring(ledamount()) .. " leds")
delay(500) -- Waits X millissecs
waitframes(5) -- waits X frames, where a 'frame' is defined in full refreshes
