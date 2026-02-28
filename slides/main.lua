package.path = "./?.lua"

require "util"
require "load_editors"

scale = 1
local scroll_key = "vv_slides_scroll_y"

local function save_scroll()
    window.sessionStorage:setItem(
        scroll_key, tostring(window.scrollY)
    )
end

local function load_scroll()
    local sy = window.sessionStorage:getItem(scroll_key)
    if is_none(sy) then return nil end
    return tonumber(sy)
end

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

    window:onresize()
    local sy = load_scroll()
    if sy then window:scroll(0, sy) end

    window:addEventListener("scroll", save_scroll)
    window:addEventListener("beforeunload", save_scroll)

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

function add_slide(o)
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
    pre.style.top = "160px"

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
    spacer.style.height = "380px"

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

    if o.spacer then
        spacer.style.height = o.spacer
    end
end

function read_file(path)
    local xhr = js.new(window.XMLHttpRequest)
    xhr:open("GET", path, false)
    xhr:send()
    local ok = (
        xhr.status >= 200 and xhr.status < 300
    ) or xhr.status == 304
    assert(ok,
        "read_file failed for " .. path
        .. " (status " .. tostring(xhr.status) .. ")"
    )
    return xhr.responseText
end

require "slides"

init()
