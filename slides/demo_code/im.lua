local a = { type = "a", x = 50, y = 50 }
local b = { type = "b", x = 150, y = 50 }
local c = { type = "c", x = 100, y = 100 }

local atoms = { a, b, c }
local bonds = { { a, c } }

local function draw()
    clear()

    ctx.strokeStyle = "#777"
    for _, b in ipairs(bonds) do
        line(b[1].x, b[1].y, b[2].x, b[2].y)
    end

    for _, a in ipairs(atoms) do
        ctx.fillStyle = "#999"
        circle(a.x, a.y, 20)
        draw_text(a.type, a.x - 6, a.y - 8)
    end
end

local track_mouse = false
function loop(dt)
    if mx > 0 and mx < 400 and my > 0 and my < 400 then
        track_mouse = true
    end
    if track_mouse then
        c.x = fri_lerp(c.x, mx, 0.2, dt)
        c.y = fri_lerp(c.y, my, 0.2, dt)
    end

    for _, a in ipairs(atoms) do
        a.x = clamp(a.x, 20, 380)
        a.y = clamp(a.y, 20, 380)
    end

    draw()
end
