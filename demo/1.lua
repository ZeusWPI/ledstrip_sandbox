
while true do
  for i=1,ledamount() do
    if i > 1 then
      led(i - 1, 0, 0, 0)
    end
    led(i, 255, 0, 0)
    delay(100)
  end
  led(ledamount(), 0, 0, 0)
end
