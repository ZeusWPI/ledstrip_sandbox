function all_leds(red, green, blue)
  for bar=1,ledamount() do
    led(bar, red, green, blue)
  end
end

while true do
  print(ledamount())
  all_leds(255, 128, 0)
  delay(1000)
  all_leds(0, 128, 255)
  delay(1000)
end
