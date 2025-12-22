mailbox.subscribe("frigo/ordered")

while true do
    local msg = mailbox.consume("frigo/ordered")
    if #msg > 0 then
        state.setActiveByName("alarm")
    else
        time.waitFrames(1)
    end
end
