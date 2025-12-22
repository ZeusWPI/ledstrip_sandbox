assert(led.count == 690, "This script must have exactly 690 leds assigned")

colors = {{255, 0, 0}, {255, 255, 0}, {0, 255, 0}, {0, 0, 255}, {148, 0, 211}}
color_change_delay = bit.lshift(1, 8)
brightness = 16

led.setAll(0, 16, 0)

ballwidth = 8

mailbox.subscribe("tap_jackpot/roulette")

function roulettespin(msg)
    led.setAll(0, 16, 0)

    led.set(0, 245, 180, 0)
    led.set(690 - 20, 245, 180, 0)

    ballpos = math.random(0, led.count - 1)
    startslowpos = math.random(0, led.count - 1)
    if startslowpos <= 170 then
        startslowpos = math.random(led.count / 2, led.count - 1)
    end
    if startslowpos >= 210 then
        startslowpos = math.random(led.count / 2, led.count - 1)
    end

    if msg == "win" then
        startslowpos = 200
    end

    for i = ballpos,ballpos + ballwidth,1
    do
        led.set(i, 255, 0, 0)
    end

    beginspeed = 200.0
    speed = beginspeed
    slowfactor = 0.99999999
    slowfactor2 = 0.999995
    slowing = 0
    while true do
        if ballpos == startslowpos then
            slowing = 1
        end

        if slowing == 1 then
            slowfactor = slowfactor * slowfactor2
            speed = speed * slowfactor
        end

        if speed <= 7.0 then
            break
        end

        led.set(ballpos, 0, 16, 0)
        ballpos = ballpos + 1
        ballpos = ballpos % led.count
        ballend = ballpos + ballwidth
        ballend = ballend % led.count
        led.set(ballend, 255, 0, 0)
        led.set(690 - 7, 245, 16, 0)
        led.set(690 - 30, 245, 16, 0)
        time.sleepMsecs(1000.0 / speed)
    end


    time.sleepMsecs(5000)

end

while true do
    local msg = mailbox.consume("tap_jackpot/roulette")
    if #msg > 0 then
        state.setActiveByName("esoterisch")
        log("Got msg: ", msg)
        roulettespin(msg)
        log("Reverting state")
        state.setDefaultActive()
    else
        time.waitFrames(1)
    end
end


