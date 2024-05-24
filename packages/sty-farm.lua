require "atf"
LENGTH = 26
INTERVAL = 500
---@diagnostic disable-next-line: undefined-field
TIMER_ID = os.startTimer(1)
local timer_start = os.clock()
local startNext = true
local function go()
    print "starting"
    turtle.selectItem("coal")
    turtle.refuel()
    turtle.select(1)
    local function farm()
        local _, item = turtle.inspectDown()
        if item then
            if item.state then
                if item.state.age then
                    if item.state.age >= 7 then
                        turtle.digDown()
                    end
                end
            end
        end
        turtle.selectItem("seeds")
        turtle.placeDown()
    end
    local function line()
        for i = 1, math.ceil(LENGTH / 2) do
            print(i)
            farm()
            for _ = 1, 3 do
                turtle.force()
                farm()
            end
            turtle.turnRight()
            turtle.force()
            turtle.turnRight()
            farm()
            for _ = 1, 3 do
                turtle.force()
                farm()
            end
            turtle.turnLeft()
            turtle.force()
            turtle.turnLeft()
        end
    end
    turtle.force()
    turtle.turnLeft()
    line()
    for _ = 1, 8 do
        turtle.force()
        farm()
    end
    turtle.turnLeft()
    turtle.force()
    turtle.turnLeft()
    line()
    for _ = 1, 8 do
        turtle.force()
        farm()
    end
    turtle.turnLeft()
    print "looking for chest"
    local _, block = turtle.inspectDown()
    if block then
        if block then
            if block.name:sub(#block.name - #"chest" + 1, #block.name) == "chest" then
                print "chest found"
                for i = 1, 16 do
                    turtle.select(i)
                    turtle.dropDown()
                end
            else
                print "chest not found"
            end
        end
    end
    ---@diagnostic disable-next-line: undefined-field
    TIMER_ID = os.startTimer(INTERVAL)
    timer_start = os.clock()
    startNext = false
end

local paused = false
while true do
    if startNext and not paused then
        term.setBackgroundColor(colors.black)
        term.clear()
        term.setCursorPos(1, 1)
        go()
    end
    term.setTextColor(colors.red or colors.gray)
    term.write "fuel: "
    term.setTextColor(colors.white)
    print(("%d/%d (%.2f%%)"):format(turtle.getFuelLevel(), turtle.getFuelLimit(), turtle.getFuelLevel() / turtle.getFuelLimit() * 100))
    term.setTextColor(colors.red or colors.gray)
    term.write "next: "
    term.setTextColor(colors.white)
    print(("%.2f"):format(INTERVAL - (os.clock() - timer_start)))
    if paused then
        term.setTextColor(colors.red or colors.gray)
        term.write "PAUSED..."
        term.setTextColor(colors.white)
    end
    ---@diagnostic disable-next-line: undefined-field
    local event = { os.pullEvent() }
    if event[1] == "timer" and event[2] == TIMER_ID then
        startNext = true
    end
    if event[1] == "char" and event[2] == "r" then
        turtle.selectItem("coal")
        turtle.refuel()
    end
    if event[1] == "key" and event[2] == keys.space then
        paused = not paused
    end
end