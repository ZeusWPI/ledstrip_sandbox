-- script to set leds depending on CO2 value
-- TODO make pull-based instead of push-based

function all_leds(red, green, blue)
  for bar=1,ledamount() do
    led(bar, red, green, blue)
  end
end

all_leds(0, 0, 255)

while true do
  msg = getmessage()
  if msg ~= nil then
    value = tonumber(msg)
    if value < 900 then
      all_leds(0, 255, 0)
    elseif value < 1200 then
      all_leds(255, 128, 0)
    else
      all_leds(255, 0, 0)
    end
  else
    delay(1000)
  end
end
