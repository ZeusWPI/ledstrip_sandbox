morse = {a = '.-', b = '-...', c = '-.-.', d = '-..', e = '.', f = '..-.', g = '--.', h ='....', i = '..', j = '.---', k = '-.-', l = '.-..', m = '--', n = '-.', o = '---', p = '.--.', q = '--.-', r = '.-.', s = '...', t = '-', u = '..-', v = '...-', w = '.--', x = '-..-', y = '-.--', z = '--..'}

morse['0'] = '-----'
morse['1'] = '.----'
morse['2'] = '..---'
morse['3'] = '...--'
morse['4'] = '....-'
morse['5'] = '.....'
morse['6'] = '-....'
morse['7'] = '--...'
morse['8'] = '---..'
morse['9'] = '----.'

morse[','] = '..-..'
morse['.'] = '.-.-.-'
morse['?'] = '..--..'
morse[';'] = '-.-.-'
morse[':'] = '---...'
morse['/'] = '-..-.'
morse['+'] = '.-.-.'
morse['-'] = '-....-'
morse['='] = '-...-'
morse['!'] = '-.-.--'
morse['('] = '-.--.'
morse[')'] = '-.--.-'
morse['&'] = '.-...'



function all_leds(red, green, blue)
  for bar=1,ledamount() do
    led(bar, red, green, blue)
  end
end

function tableconcat(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end


all_leds(10, 0, 0)

delay(1000)
all_leds(100, 0, 10)

i = 0
while getmessage() ~= nil do
  all_leds(0, 0, i)
  i = i + 1
  delay(1000)
end

colors = {{255, 0, 0}, {255, 128, 0}, {255, 255, 0}, {0, 255, 0}, {0, 0, 255}, {148, 0, 211}}

while true do
  msg = getmessage()
  if msg ~= nil then
    all_leds(255, 255, 255)
    translated = {}
    msg = string.lower(msg)
    local current = 0
    for c in msg:gmatch"." do
      if c == ' ' then
        tableconcat(translated, {0, 0, 0, 0, 0, 0, 0})
      elseif morse[c] ~= nil then
        current = current + 1
        for mc in morse[c]:gmatch"." do
          if mc == '.' then
            tableconcat(translated, {current, 0})
          elseif mc == '-' then
            tableconcat(translated, {current, current, current, 0})
          end
        end
        tableconcat(translated, {0, 0})
      else
        tableconcat(translated, {0, 0, 0})
      end
    end

    for timestep=0,(#translated+ledamount()) do
      print(timestep)
      for i=1,ledamount() do
        local coloridx = translated[i + timestep - ledamount()]
        if coloridx ~= 0 and coloridx ~= nil then
          local color = colors[(coloridx % #colors) + 1]
          led(i, color[1], color[2], color[3])
        else
          led(i, 0, 0, 0)
        end
      end
      delay(200)
    end
  else
    delay(1000)
    all_leds(20, 0, 20)
  end
end