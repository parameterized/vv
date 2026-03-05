function round(x)
    return math.floor(x + 0.5)
end

function clamp(x, a, b)
    return math.min(math.max(x, a), b)
end

function lerp(a, b, t)
    return a * (1 - t) + b * t
end

function fri_lerp(a, b, t, dt)
    -- frame rate independent(ish) lerp
    local alpha = 1 - math.exp(-60 * t * dt)
    return lerp(a, b, alpha)
end

function dist(x1, y1, x2, y2)
    if type(x1) == "table" then
        y1 = y1 or {}
        x2, y2 = y1.x, y1.y
        x1, y1 = x1.x, x1.y
    end
    if x2 == nil then
        x2, y2 = 0, 0
    end
    return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end

function draw_text(s, x, y)
    ctx.font = "20px sans-serif"
    ctx.textBaseline = "top"
    ctx.fillStyle = "#ddd"
    ctx:fillText(s, x, y)
end

function circle(x, y, r)
    ctx:beginPath()
    ctx:ellipse(x, y, r, r, 0, 0, 2 * math.pi)
    ctx:fill()
end

function line(x1, y1, x2, y2)
    ctx.lineWidth = 4
    ctx:beginPath()
    ctx:moveTo(x1, y1)
    ctx:lineTo(x2, y2)
    ctx:stroke()
end
