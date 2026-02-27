package.path = "./?.lua"

require "util"
require "load_editors"

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
    fix_line_numbers()
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

    load_editors()

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
    slide:append(h1)
    h1.innerHTML = o.h1 or ""

    local pre = document:createElement("pre")
    slide:append(pre)
    pre.innerHTML = o.pre or ""
    pre.style.left = "100px"
    pre.style.top = "180px"

    local function new_code_div(src)
        local code_div = document:createElement("div")
        code_div.className = "code-div"
        code_div.style.height = "400px"
        code_div:append(document:createElement("textarea"))
        local script = document:createElement("script")
        script.type = "text/plain"
        script.innerHTML = src
        code_div:append(script)
        return code_div
    end

    local spacer = document:createElement("div")
    slide:append(spacer)
    spacer.style.height = "400px"

    if o.code_hidden then
        spacer.style.height = o.code and "60px" or "240px"
        local details = document:createElement("details")
        local summary = document:createElement("summary")
        details:append(summary)
        summary.innerHTML = "ignore this part"
        local code_div = new_code_div(o.code_hidden)
        details:append(code_div)
        code_div.style.height = "300px"
        slide:append(details)
    end
    if o.code then
        slide:append(new_code_div(o.code))
    end
end


add_slide {
    code_hidden = [[
function draw_text(s, x, y)
    ctx.font = "20px sans-serif"
    ctx.textBaseline = "top"
    ctx.fillStyle = "#ddd"
    ctx:fillText(s, x, y)
end
    ]],
}

add_slide {
    h1 = "code",
    pre = [[
code
    ]],
    code = [[
local delta = {
    [0] = {
        A = {1, "R", "B"},
        B = {0, "R", "C"},
        C = {1, "L", "C"},
    },
    [1] = {
        A = {1, "L", "H"},
        B = {1, "R", "B"},
        C = {1, "L", "A"},
    },
}

local tape, state, pos = {}, "A", 0
local y = 20

local function show()
    local s = ""
    for i=-2, 5 do
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
    pos = pos + ({L=-1, R=1})[d]
    window:setTimeout(step, 100)
end

clear()
step()
    ]],
}

add_slide {}

init()
