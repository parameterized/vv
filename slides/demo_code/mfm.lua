local grid = {}
local windows = {}
local res = 25
for i = 1, res do
    grid[i] = {}
    for j = 1, res do
        grid[i][j] = {
            type = rng() < 0.2 and "sand" or "air",
            color = {
                r = rng(240, 250),
                g = rng(140, 180),
                b = rng(190, 210),
            }
        }
    end
end

local function draw_cell(cell, i, j)
    if cell.type ~= "air" then
        local c = cell.color
        ctx.fillStyle = (
            "rgb(" .. c.r .. " "
            .. c.g .. " " .. c.b .. ")"
        )
        local s = 400 / res
        local x, y = (j - 1) * s, (i - 1) * s
        ctx:fillRect(x, y, s, s)
    end
end

local function draw()
    clear()
    for i, row in ipairs(grid) do
        for j, cell in ipairs(row) do
            draw_cell(cell, i, j)
        end
    end

    ctx.fillStyle = "rgb(200 200 200 / 50%)"
    for _, w in ipairs(windows) do
        local s = 400 / res
        local x, y = (w.j - 1) * s, (w.i - 1) * s
        local f = math.min(
            4 * w.timer, 4 * (1 - w.timer), 1
        )
        circle(x + s / 2, y + s / 2, 2 * s * f)
    end
end

local function try_add_window()
    local i = 1 + math.floor(rng(res))
    local j = 1 + math.floor(rng(res))

    for _, w in ipairs(windows) do
        if dist(i, j, w.i, w.j) < 4 then return end
    end

    table.insert(windows, {
        i = i,
        j = j,
        timer = 1,
        speed = rng(2, 4),
        acted = false,
    })
end

function loop(dt)
    for _ = 1, 10 do
        try_add_window()
    end

    for i = #windows, 1, -1 do
        local w = windows[i]
        w.timer = w.timer - w.speed * dt
        if w.timer < 0.5 and not w.acted then
            local center = grid[w.i][w.j]
            local down = (grid[w.i + 1] or {})[w.j]
            if (down or {}).type == "air" then
                grid[w.i + 1][w.j] = center
                grid[w.i][w.j] = down
            end

            w.acted = true
        end
        if w.timer < 0 then
            table.remove(windows, i)
        end
    end

    draw()
end

draw()
