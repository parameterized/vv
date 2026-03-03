local colors = {
    cons0 = "#c48",
    cons1 = "#c84",
    cons2 = "#48c",
    era = "#c66",
    free = "#ccc",
    wire = "#84c",
    cell = "#aaa",
}

local primary = {
    cons0 = 1, dup0 = 1, era = 1, free = 1
}
local ports, edges
do
    local era = { type = "era", x = 100, y = 50 }
    local cons0 = { type = "cons0", x = 200, y = 150 }
    local cons1 = { type = "cons1", x = 250, y = 250 }
    local cons2 = { type = "cons2", x = 150, y = 250 }
    local free1 = { type = "free", x = 300, y = 350 }
    local free2 = { type = "free", x = 200, y = 350 }

    ports = { era, cons0, cons1, cons2, free1, free2 }
    edges = {
        [{ era, cons0 }] = "wire",
        [{ cons0, cons1 }] = "cell",
        [{ cons0, cons2 }] = "cell",
        [{ cons1, free1 }] = "wire",
        [{ cons2, free2 }] = "wire",
    }
end

local function draw()
    clear()

    for p12, etype in pairs(edges) do
        local p1, p2 = unpack(p12)
        ctx.strokeStyle = colors[etype]
        line(p1.x, p1.y, p2.x, p2.y)
    end
    for _, p in ipairs(ports) do
        ctx.fillStyle = colors[p.type]
        circle(p.x, p.y, 10)
    end
end

local function reduce(p1, p2)
    for _, p12 in ipairs { { p1, p2 }, { p2, p1 } } do
        p1, p2 = unpack(p12)
        if p1.type == "era" and p2.type == "cons0" then
            local p2_aux = {}
            for e, et in pairs(edges) do
                if et == "cell" and e[1] == p2 then
                    table.insert(p2_aux, e[2])
                end
            end
            for _, p in ipairs(p2_aux) do
                p.type = "era"
            end
            local rm_es = {}
            for e, _ in pairs(edges) do
                if e[1] == p2 or e[2] == p2 then
                    table.insert(rm_es, e)
                end
            end
            for _, e in ipairs(rm_es) do
                edges[e] = nil
            end
            for i = #ports, 1, -1 do
                local p = ports[i]
                if p == p1 or p == p2 then
                    table.remove(ports, i)
                end
            end
            return true
        end
    end
end

local function contract(dt)
    for p12, _ in pairs(edges) do
        local p1, p2 = unpack(p12)
        if primary[p1.type] and primary[p2.type] then
            if dist(p1.x, p1.y, p2.x, p2.y) < 20 then
                if reduce(p1, p2) then return end
            else
                local cx = (p1.x + p2.x) / 2
                local cy = (p1.y + p2.y) / 2
                p1.x = fri_lerp(p1.x, cx, 0.1, dt)
                p1.y = fri_lerp(p1.y, cy, 0.1, dt)
                p2.x = fri_lerp(p2.x, cx, 0.1, dt)
                p2.y = fri_lerp(p2.y, cy, 0.1, dt)
            end
        end
    end
end

function loop(dt)
    contract(dt)

    draw()
end

draw()
