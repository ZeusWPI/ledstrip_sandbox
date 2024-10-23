local colors = {
    {255,   0,   0},
    {255, 128,   0},
    {255, 255,   0},
    {  0, 255,   0},
    {  0,   0, 255},
    {148,   0, 211}
}

local morse = {
    ['a'] = '.-',
    ['b'] = '-...',
    ['c'] = '-.-.',
    ['d'] = '-..',
    ['e'] = '.',
    ['f'] = '..-.',
    ['g'] = '--.',
    ['h'] ='....',
    ['i'] = '..',
    ['j'] = '.---',
    ['k'] = '-.-',
    ['l'] = '.-..',
    ['m'] = '--',
    ['n'] = '-.',
    ['o'] = '---',
    ['p'] = '.--.',
    ['q'] = '--.-',
    ['r'] = '.-.',
    ['s'] = '...',
    ['t'] = '-',
    ['u'] = '..-',
    ['v'] = '...-',
    ['w'] = '.--',
    ['x'] = '-..-',
    ['y'] = '-.--',
    ['z'] = '--..',
    ['0'] = '-----',
    ['1'] = '.----',
    ['2'] = '..---',
    ['3'] = '...--',
    ['4'] = '....-',
    ['5'] = '.....',
    ['6'] = '-....',
    ['7'] = '--...',
    ['8'] = '---..',
    ['9'] = '----.',
    [','] = '..-..',
    ['.'] = '.-.-.-',
    ['?'] = '..--..',
    [';'] = '-.-.-',
    [':'] = '---...',
    ['/'] = '-..-.',
    ['+'] = '.-.-.',
    ['-'] = '-....-',
    ['='] = '-...-',
    ['!'] = '-.-.--',
    ['('] = '-.--.',
    [')'] = '-.--.-',
    ['&'] = '.-...'
}
 
function tableconcat(t1, t2)
    for i = 1, #t2 do
        t1[#t1 + 1] = t2[i]
    end
    return t1
end

mailbox.subscribe("morsemessage")

led.setAll(10, 0, 0)

time.sleepMsecs(1000)
led.setAll(100, 0, 10)

while true do
    local msg = mailbox.consume("morsemessage")
    if #msg > 0 then
        led.setAll(255, 255, 255)
        time.waitFrames(2)

        msg = string.lower(msg)

        local translated = {}
        local i = 0
        for c in msg:gmatch(".") do
            if c == ' ' then
                tableconcat(translated, {0, 0, 0, 0, 0, 0, 0})
            elseif morse[c] ~= nil then
                i = i + 1
                for morse_c in morse[c]:gmatch(".") do
                    if morse_c == '.' then
                        tableconcat(translated, {i, 0})
                    elseif morse_c == '-' then
                        tableconcat(translated, {i, i, i, 0})
                    end
                end
                tableconcat(translated, {0, 0})
            else
                tableconcat(translated, {0, 0, 0})
            end
        end

        for timestep = 0, (#translated + led.count) do
            for i = 0, led.count - 1 do
                local color_i = translated[i + timestep - led.count]
                if color_i ~= nil and color_i ~= 0 then
                    local color = colors[(color_i % #colors) + 1]
                    led.set(i, color[1], color[2], color[3])
                else
                    led.set(i, 0, 0, 0)
                end
            end
            time.sleepMsecs(100)
        end
    else
        time.sleepMsecs(1000)
        led.setAll(20, 0, 20)
    end
end
