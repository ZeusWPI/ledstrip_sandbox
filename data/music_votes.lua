FOR_COLOR = { 0x00, 0xFF, 0x00 }
AGAINST_COLOR = { 0xFF, 0x00, 0x00 }
UNDECIDED_COLOR = { 0xFF, 0x00, 0xFF }

PAUSE_TOPIC = "music/events/paused"
STOP_TOPIC = "music/events/stopped"
PLAYING_TOPIC = "music/current_song_info"
VOTE_TOPIC = "music/votes"

current_song = ""

local function round(a)
    return math.floor(a + 0.5)
end

local function fixColorChannel(color)
    return round(color * led.maxBrightness() / 255)
end

local function fixColors(colorTable)
    local r, g, b = unpack(colorTable)
    return fixColorChannel(r), fixColorChannel(g), fixColorChannel(b)
end

local function showVotes(votesFor, votesAgainst)
    if votesFor == 0 and votesAgainst == 0 then
        led.setAll(fixColors(UNDECIDED_COLOR))
    else
        local ledsFor = led.count * votesFor / (votesFor + votesAgainst)
        led.setSlice(0, ledsFor, fixColors(FOR_COLOR))
        led.setSlice(ledsFor, led.count, fixColors(AGAINST_COLOR))
    end
end


local function handlePauseUpdate(jsonMsg)
    if jsonMsg == "" then return end
    log("Song stopped")
    led.setAll(fixColors(UNDECIDED_COLOR))
end

local function handleVoteUpdate(jsonMsg)
    if jsonMsg == "" then return end
    local success, msg = pcall(json.loads, jsonMsg)
    if not success then log("invalid vote json: ", msg) return end
    if success and msg["songId"] == current_song then
        local votesFor = msg["votesFor"]
        local votesAgainst = msg["votesAgainst"]
        log("Votes updated: ", votesFor, " - ", votesAgainst)
        showVotes(votesFor, votesAgainst)
    end
end

local function handlePlayUpdate(jsonMsg)
    if jsonMsg == "" then return end
    local success, msg = pcall(json.loads, jsonMsg)
    if not success then log("invalid play json: ", msg) return end
    current_song = msg["spotifyId"]
    log("Song playing: ", current_song)
    local votesFor = msg["votesFor"]
    local votesAgainst = msg["votesAgainst"]
    log("Votes updated: ", votesFor, " - ", votesAgainst)
    showVotes(votesFor, votesAgainst)
end

function Main()
    log("Main entry")

    led.setAll(fixColors(UNDECIDED_COLOR))

    mailbox.subscribe(PLAYING_TOPIC)
    mailbox.subscribe(PAUSE_TOPIC)
    mailbox.subscribe(STOP_TOPIC)
    mailbox.subscribe(VOTE_TOPIC)

    while true do
        handlePlayUpdate(mailbox.consume(PLAYING_TOPIC))
        handlePauseUpdate(mailbox.consume(PAUSE_TOPIC))
        handlePauseUpdate(mailbox.consume(STOP_TOPIC))
        handleVoteUpdate(mailbox.consume(VOTE_TOPIC))
        time.waitFrames(1)
    end
end

Main()