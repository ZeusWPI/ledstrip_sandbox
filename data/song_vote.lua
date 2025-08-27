FOR_COLOR = {0x00, 0xFF, 0x00}
AGAINST_COLOR = {0xFF, 0x7F, 0x00}
UNDECIDED_COLOR = {0xFF, 0x00, 0xFF}


local function round(a)
return math.floor(a+0.5)
end
local function fixColorChannel(color)
    return round(color*led.maxBrightness/255)
end

local function fixColors(colorTable) 
local r, g, b = unpack(colorTable)
return fixColorChannel(r), fixColorChannel(g), fixColorChannel(b)   
end

led.setAll(fixColors(UNDECIDED_COLOR))

local function onVoteUpdate(votesFor, votesAgainst) 
if votesAgainst == 0 and votesFor == 0 then
    led.setAll(fixColors(UNDECIDED_COLOR))
else
    local ledsFor = led.count * votesFor / (votesFor + votesAgainst)
    led.setSlice(0, ledsFor, fixColors(FOR_COLOR))
    led.setSlice(ledsFor, led.count, fixColors(AGAINST_COLOR))
end
end

onVoteUpdate(7, 2)