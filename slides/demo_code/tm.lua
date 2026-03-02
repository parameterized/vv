local delta = {
    [0] = {
        A = { 1, "R", "B" },
        B = { 0, "R", "C" },
        C = { 1, "L", "C" },
    },
    [1] = {
        A = { 1, "L", "H" },
        B = { 1, "R", "B" },
        C = { 1, "L", "A" },
    },
}

local tape, state, pos = {}, "A", 0
local config_hist = {}

local function config_str()
    local s = ""
    for i = -2, 5 do
        s = s .. (
            tostring(tape[i] or 0)
            .. (i == pos and state or " ")
        )
        if i < 5 then s = s .. " " end
    end
    return s
end
table.insert(config_hist, config_str())

local function draw()
    clear()
    local y = 20
    for _, s in ipairs(config_hist) do
        draw_text(s, 100, y)
        y = y + 24
    end
end

local function step()
    if state == "H" then return end

    local sym = tape[pos] or 0
    local d
    tape[pos], d, state = unpack(
        delta[sym][state]
    )
    pos = pos + ({ L = -1, R = 1 })[d]
    table.insert(config_hist, config_str())
end

local fps = 10
local timer = 1 / fps

function loop(dt)
    timer = timer - dt
    if timer < 0 then
        step()
        timer = math.max(timer + 1 / fps, 0)
    end
    draw()
end

draw()
