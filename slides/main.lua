package.path = "./?.lua"

require "util"

local scale = 1
function window:onresize()
    local new_scale = window.innerWidth / 1600
    local new_scroll = (
        window.scrollY + window.innerHeight / 2
    ) * new_scale / scale - window.innerHeight / 2 + 0.5
    scale = new_scale

    local slides = document:querySelector(".slides")
    slides.style.transform = "scale(" .. tostring(scale) .. ")"
    local n_slides = document:querySelectorAll("x-slide").length
    slides.style.height = tostring(
        900 * n_slides * math.min(scale, 1)
    ) .. "px"

    window:scroll(0, new_scroll)
    window:fix_line_numbers()
end

local function init()
    window:renderMathInElement(document.body, js_obj {
        delimiters = js_arr(
            js_obj { left = "$$", right = "$$", display = true },
            js_obj { left = "$", right = "$", display = false }
        ),
        throwOnError = false,
        ignoredTags = js_arr(
            "script", "noscript", "style", "textarea", "code",
            "option"
        ),
        output = "html",
    })

    window:load_editors()

    local _scroll = window.scrollY
    window:onresize()
    window:scroll(0, _scroll)
    document.documentElement.classList:remove("hidden")
end

local function next_slide(step)
    if step == nil then step = 1 end
    local cur_slide = math.floor(
        (window.scrollY + window.innerHeight / 2) / 900 / scale
    )
    window:scrollTo(js_obj {
        top = (
            cur_slide + step + 0.5
        ) * 900 * scale - window.innerHeight / 2 + 0.5,
        behavior = "smooth",
    })
end

function window:onkeydown(e)
    if e.target.tagName == "TEXTAREA" then return end

    local k = e.key
    if k == "0" then
        window:scrollTo(js_obj { top = 0, behavior = "smooth" })
    elseif k == "G" then
        local n_slides = document:querySelectorAll("x-slide").length
        window:scrollTo(js_obj {
            top = 900 * n_slides * scale - window.innerHeight,
            behavior = "smooth",
        })
    elseif ({ ArrowUp = 1, ArrowLeft = 1, k = 1 })[k] then
        if not e.shiftKey and not e.altKey then
            e:preventDefault()
            next_slide(-1)
        end
    elseif ({ ArrowDown = 1, ArrowRight = 1, j = 1 })[k] then
        if not e.shiftKey and not e.altKey then
            e:preventDefault()
            next_slide()
        end
    end
end

local function add_slide(o)
    local slides = document:querySelector(".slides")
    local slide = document:createElement("x-slide")
    slides:append(slide)

    local h1 = document:createElement("h1")
    h1.innerHTML = o.h1
    slide:append(h1)
    slide.innerHTML = slide.innerHTML .. (o.body or "")

    local function new_code_div(src)
        local code_div = document:createElement("div")
        code_div.className = "code-div"
        code_div.style.height = "300px"
        code_div:append(document:createElement("textarea"))
        local script = document:createElement("script")
        script.type = "text/plain"
        script.innerHTML = src
        code_div:append(script)
        return code_div
    end

    local spacer = document:createElement("div")
    spacer.style.height = "300px"
    slide:append(spacer)

    if o.code_hidden then
        spacer.style.height = "150px"
        local details = document:createElement("details")
        local summary = document:createElement("summary")
        summary.innerHTML = "ignore this part"
        details:append(summary)
        local code_div = new_code_div(o.code_hidden)
        code_div.style.height = "280px"
        details:append(code_div)
        slide:append(details)
    end
    if o.code then
        slide:append(new_code_div(o.code))
    end
end

add_slide {
    h1 = "code",
    code_hidden = [[
dist = (x1, y1, x2, y2) => Math.sqrt(
    (x2 - x1)**2 + (y2 - y1)**2
)
lerp = (a, b, t) => a * (1 - t) + b * t

draw_cell = ({x=150, y=150, angle=0, n_ports=1, label="?"}) => {
    const _mat = ctx.getTransform()
    ctx.translate(x, y)
    ctx.rotate(angle)

    ctx.font = "32px sans-serif"
    ctx.textAlign = "center"
    ctx.textBaseline = "middle"

    ctx.strokeStyle = "#ddd"
    ctx.lineCap = "round"
    ctx.lineJoin = "round"
    ctx.lineWidth = 2

    ctx.fillStyle = "SteelBlue"

    if (n_ports === 1) {
        // circle
        ctx.beginPath()
        ctx.arc(-30, 0, 30, 0, Math.PI * 2)
        ctx.fill()
        ctx.stroke()

        ctx.fillStyle = "#222"
        ctx.translate(-30, 0)
        ctx.rotate(-angle)
        ctx.fillText(label, 0, 0)
    } else {
        // triangle
        ctx.beginPath()
        ctx.moveTo(0, 0)
        ctx.lineTo(-60, 50)
        ctx.lineTo(-60, -50)
        ctx.closePath()
        ctx.fill()
        ctx.stroke()

        ctx.fillStyle = "#222"
        ctx.translate(-40, 0)
        ctx.rotate(-angle)
        ctx.fillText(label, 0, 0)
    }

    ctx.setTransform(_mat)
}

draw_wire = wire => {
    const p1 = wire[0]
    const p2 = wire[1]
    let a1 = p1.angle
    let a2 = p2.angle

    ctx.beginPath()
    ctx.moveTo(p1.x, p1.y)
    const d = dist(p1.x, p1.y, p2.x, p2.y)
    const curve_d = Math.min(d / 2, 100)
    ctx.bezierCurveTo(
        p1.x + Math.cos(a1) * curve_d,
        p1.y + Math.sin(a1) * curve_d,
        p2.x + Math.cos(a2) * curve_d,
        p2.y + Math.sin(a2) * curve_d,
        p2.x, p2.y
    )
    ctx.stroke()
}

draw_cell({x:100, y:100, label:"a"})
draw_cell({x:200, y:100, n_ports:2, label:"b"})
draw_cell({})
draw_wire([{x: 100, y: 100, angle: -1}, {x: 140, y: 100, angle: 3}])

draw_circle = (x, y) => {
    if (x === undefined) x = rng(100, 200)
    if (y === undefined) y = rng(100, 200)
    ctx.fillStyle = "SteelBlue"
    ctx.beginPath()
    ctx.ellipse(
        x, y, 20, 20,
        0, 0, Math.PI * 2
    )
    ctx.fill()
}
    ]],
    code = [[
cells = [
    {x:100, y:100, angle:-1, n_ports:1, label:"a"},
    {x:200, y:100, angle:0, n_ports:2, label:"b"},
]
wires = [
    [cells[0], {x: 140, y: 100, angle: 3}],
]

for (c of cells) draw_cell(c)
for (w of wires) draw_wire(w)
    ]],
}

add_slide {
    h1 = "more",
    code = [[
loop = dt => {
    clear()
    if (mx > 0 && my > 0 && mx < 300 && my < 300) {
        tx = mx; ty = my
    } else {
        tx = 100; ty = 100
    }
    cells[0].x = lerp(
        cells[0].x, tx, 1 - Math.exp(-6 * dt)
    )
    cells[0].y = lerp(
        cells[0].y, ty, 1 - Math.exp(-6 * dt)
    )
    for (c of cells) draw_cell(c)
    for (w of wires) draw_wire(w)
}
    ]],
}

init()
