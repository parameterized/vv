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
local y = 20

local function show()
    local s = ""
    for i = -2, 5 do
        s = s .. (
            tostring(tape[i] or 0)
            .. (i == pos and state or " ")
        )
        if i < 5 then s = s .. " " end
    end
    draw_text(s, 100, y)
    y = y + 24
end

local function step()
    show()
    if state == "H" then return end

    local sym = tape[pos] or 0
    local d
    tape[pos], d, state = table.unpack(
        delta[sym][state]
    )
    pos = pos + ({ L = -1, R = 1 })[d]
    window:setTimeout(step, 100)
end

clear()
step()
