local grid1 = {}
local grid2 = {}
local res = 25
for i = 1, res do
    grid1[i] = {}
    grid2[i] = {}
    for j = 1, res do
        grid1[i][j] = round(rng())
    end
end

local function draw()
    for i, row in ipairs(grid1) do
        for j, v in ipairs(row) do
            ctx.fillStyle = (
                "hsl(0 0 " .. (1 - v) * 100 .. "%)"
            )
            local s = 400 / res
            local x, y = (j - 1) * s, (i - 1) * s
            ctx:fillRect(x, y, s, s)
        end
    end
end

local function step()
    for k1 = 0, res * res - 1 do
        local i = math.floor(k1 / res) + 1
        local j = k1 % res + 1
        local count = 0
        for k2 = 0, 8 do
            local di = math.floor(k2 / 3) % 3 - 1
            local dj = k2 % 3 - 1
            if not (di == 0 and dj == 0) then
                local i2 = (
                    i - 1 + di
                ) % res + 1
                local j2 = (
                    j - 1 + dj
                ) % res + 1
                count = count + grid1[i2][j2]
            end
        end
        if grid1[i][j] == 1 then
            grid2[i][j] = (
                count > 1 and count < 4 and 1 or 0
            )
        else
            grid2[i][j] = count == 3 and 1 or 0
        end
    end

    grid1, grid2 = grid2, grid1
end

local fps = 24
local timer = 1 / fps
draw()

function loop(dt)
    timer = timer - dt
    if timer > 0 then return end

    timer = math.max(timer + 1 / fps, 0)
    step()
    draw()
end
