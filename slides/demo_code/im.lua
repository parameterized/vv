Net = {}
Net.__index = Net

local atom_mt = {
    __call = function(t)
        local a
        return function()
            a = next(t, a)
            return a
        end
    end
}
local bond_mt = {
    __call = function(t)
        local a1 = next(t)
        local a2
        return function()
            repeat
                a2 = next(t[a1 or {}] or {}, a2)
                if not a2 then a1 = next(t, a1) end
                if not a1 then return end
            until a2
            return a1, a2
        end
    end
}

setmetatable(Net, {
    __call = function(self)
        return setmetatable({
            atoms = setmetatable({}, atom_mt),
            bonds = setmetatable({}, bond_mt)
        }, self)
    end,
})

function Net:has(a1, _a2)
    if _a2 == nil then
        return self.atoms[a1]
    else
        return (self.bonds[a1] or {})[_a2]
    end
end

function Net:add(a1, _a2, ...)
    if _a2 == nil then
        a1.type = a1.type or a1[1]
        a1.x = a1.x or a1[2]
        a1.y = a1.y or a1[3]

        self.atoms[a1] = 1
        return a1
    else
        self.bonds[a1] = self.bonds[a1] or {}
        self.bonds[_a2] = self.bonds[_a2] or {}
        self.bonds[a1][_a2] = 1
        self.bonds[_a2][a1] = 1
        if ... then self:add(_a2, ...) end
    end
end

function Net:drop(a1, _a2)
    if _a2 == nil then
        self.atoms[a1] = nil
        self.bonds[a1] = nil
        for _, b in pairs(self.bonds) do
            b[a1] = nil
        end
    else
        (self.bonds[a1] or {})[_a2] = nil
        (self.bonds[_a2] or {})[a1] = nil
    end
end

function Net:split(a)
    local a2 = {}
    for k, v in pairs(a) do a2[k] = v end
    a2 = self:add(a2)
    for a3 in self:neighbors(a) do
        self:add(a2, a3)
    end
    return a2
end

function Net:merge(...)
    local t = { ... }
    local m = {}
    for k, v in pairs(t[1]) do m[k] = v end
    for i = 2, #t do
        m.x = m.x + t[i].x
        m.y = m.y + t[i].y
    end
    m.x, m.y = m.x / #t, m.y / #t
    m = self:add(m)
    for _, a in ipairs(t) do
        for a2 in self:neighbors(a) do
            self:add(m, a2)
        end
        self:drop(a)
    end
    return m
end

function Net:neighbors(a)
    local t = self.bonds[a] or {}
    local a2
    return function()
        a2 = next(t, a2)
        return a2
    end
end

function Net:all_pairs()
    return coroutine.wrap(function()
        for a1, _ in pairs(self.atoms) do
            for a2, _ in pairs(self.atoms) do
                if a1 ~= a2 then
                    coroutine.yield(a1, a2)
                end
            end
        end
    end)
end

local net = Net()
local track_mouse
local target_dist = 100
do
    local ap = net:add { "a'", 100, 250 }
    local bp = net:add { "b'", 300, 250 }
    local a_in = net:add { "<>", 150, 350 }
    local a_out = net:add { ">>", 250, 350 }

    local a = net:add { "a", 200, 100 }
    local c = net:add { "c", 200, 50 }

    net:add(ap, a_in, a_out, bp, ap)
    net:add(a, c)

    track_mouse = a_out
end

local function draw()
    clear()

    ctx.strokeStyle = "#00a050"
    for a1, a2 in net.bonds() do
        line(a1.x, a1.y, a2.x, a2.y)
    end

    ctx:save()
    ctx.textAlign = "center"
    for a in net.atoms() do
        ctx.fillStyle = "#0070c0"
        circle(a.x, a.y, 20)
        draw_text(a.type, a.x, a.y - 8)
    end
    ctx:restore()
end

local function lerp_pos(a, x, y, t, dt)
    a.x = fri_lerp(a.x, x, t, dt)
    a.y = fri_lerp(a.y, y, t, dt)
end

local function complement(atype)
    if atype:sub(-1) == "'" then
        return atype:sub(1, -2)
    else
        return atype .. "'"
    end
end

local function is_match(a1, a2)
    for _, at in ipairs { { a1, a2 }, { a2, a1 } } do
        a1, a2 = unpack(at)
        local t1, t2 = a1.type, a2.type
        if
            t2:sub(-1) == "'"
            and t1 == t2:sub(1, -2)
        then
            return true
        end
    end
    return false
end

local function is_rewriting(a)
    for dest in net:neighbors(a) do
        for a_out in net:neighbors(dest) do
            for a_in in net:neighbors(a_out) do
                -- todo: check for <>'->>'
                if
                    a_in.type == "<>"
                    and a_out.type == ">>"
                    and not net:has(a, a_in)
                    and not net:has(a, a_out)
                then
                    -- todo: random init could cause
                    -- multiple dest
                    return dest
                end
            end
        end
    end
    return false
end

function loop(dt)
    local a = track_mouse
    a.x = fri_lerp(a.x, mx, 0.1, dt)
    a.y = fri_lerp(a.y, my - 30, 0.1, dt)

    -- set movement targets
    for a in net.atoms() do
        a.tdx, a.tdy = 0, 0
    end
    for a1, a2 in net:all_pairs() do
        local dx = a2.x - a1.x
        local dy = a2.y - a1.y
        local d = math.max(dist(dx, dy), 0.01)
        local td = target_dist

        if net:has(a1, a2) then
            -- contract rewrite bonds
            local a1d = is_rewriting(a1)
            local a2d = is_rewriting(a2)
            if a1d == a2 or a2d == a1 then
                td = 0
            end
        else
            -- only push if unbonded
            td = math.max(td, d)
            -- unless its a match, one is src,
            -- and not rewriting
            local src_pair = false
            for a3 in net:neighbors(a1) do
                -- todo: check <>' and check for output
                if a3.type == "<>" then
                    src_pair = true
                end
            end
            for a3 in net:neighbors(a2) do
                if a3.type == "<>" then
                    src_pair = true
                end
            end
            if
                is_match(a1, a2)
                and src_pair
                and not is_rewriting(a1)
                and not is_rewriting(a2)
            then
                td = 0
            end
        end

        local cx = (a1.x + a2.x) / 2
        local cy = (a1.y + a2.y) / 2
        a1.tdx = a1.tdx + cx - dx / d * td / 2 - a1.x
        a1.tdy = a1.tdy + cy - dy / d * td / 2 - a1.y
    end
    -- move towards targets
    for a in net.atoms() do
        lerp_pos(a, a.x + a.tdx, a.y + a.tdy, 0.05, dt)
    end

    -- check for full input matches
    -- todo: better iter/filter style
    for a_in in net.atoms() do
        -- todo: check for <>'->>'
        if a_in.type == "<>" then
            local matched = true
            local match_pairs = {}
            for src in net:neighbors(a_in) do
                if src.type ~= ">>" then
                    match_pairs[src] = false
                    for src_match in net.atoms() do
                        -- todo: sort and filter
                        -- by dist
                        if
                            is_match(src, src_match)
                            and not
                            match_pairs[src_match]
                            and dist(src, src_match)
                            < 40
                        then
                            match_pairs[src]
                            = src_match
                        end
                    end
                end
            end
            for _, v in pairs(match_pairs) do
                if not v then matched = false end
            end
            -- todo: disable match if any rewriting

            -- choose output atom
            local out_opts = {}
            for a_out in net:neighbors(a_in) do
                if a_out.type == ">>" then
                    table.insert(out_opts, a_out)
                end
            end
            local i = 1 + math.floor(rng(#out_opts))
            local a_out = out_opts[i]
            if matched and a_out then
                -- start rewrite
                for src, src_match in pairs(
                    match_pairs
                ) do
                    -- todo: include src as
                    -- potential dest
                    for dest in net:neighbors(src) do
                        if
                            dest ~= a_in
                            and net:has(dest, a_out)
                        then
                            net:add(
                                net:split(src_match),
                                dest
                            )
                        end
                    end
                    net:drop(src_match)
                end
            end
        end
    end

    -- check for finishable rewrites
    for a_out in net.atoms() do
        -- todo: check for <>'->>'
        -- todo: make sure input is connected
        if a_out.type == ">>" then
            local in_progress = false
            local dest_ins = {}
            for dest in net:neighbors(a_out) do
                for a_r in net:neighbors(dest) do
                    if is_rewriting(a_r) == dest then
                        dest_ins[dest]
                        = dest_ins[dest] or {}
                        table.insert(
                            dest_ins[dest], a_r
                        )
                        if dist(a_r, dest) > 40 then
                            in_progress = true
                        end
                    end
                end
            end
            if not in_progress then
                for dest, ins in pairs(dest_ins) do
                    local m = net:merge(unpack(ins))
                    m.type = complement(dest.type)
                    net:drop(m, dest)
                end
            end
        end
    end

    -- keep on screen
    for a in net.atoms() do
        a.x = clamp(a.x, 20, 380)
        a.y = clamp(a.y, 20, 380)
    end

    draw()
end

draw()
