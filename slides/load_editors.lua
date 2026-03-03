---@diagnostic disable: lowercase-global

mouse = {
    x = 0,
    y = 0,
    held = { [0] = false, [1] = false, [2] = false },
}

function mouse_held(button)
    if button == nil then
        for _, held in pairs(mouse.held) do
            if held then return true end
        end
        return false
    end
    return mouse.held[button]
end

function window:onpointermove(e)
    if not e.isPrimary then return end
    mouse.x = e.clientX
    mouse.y = e.clientY
end

function window:onpointerdown(e)
    if not e.isPrimary then return end
    if mouse.held[e.button] ~= nil then
        mouse.held[e.button] = true
    end
    mouse.x = e.clientX
    mouse.y = e.clientY
end

function window:onpointerup(e)
    if not e.isPrimary then return end
    if mouse.held[e.button] ~= nil then
        mouse.held[e.button] = false
    end
end

function rng(a, b)
    v = math.random()
    if a == nil then return v end
    if b == nil then return v * a end
    return a + v * (b - a)
end

function set_locals(code_div)
    -- set ctx, bounds, mx, my, clear

    local function _clear(ctx)
        local _fs = ctx.fillStyle
        ctx.fillStyle = "#222"
        local w, h = ctx.canvas.width, ctx.canvas.height
        ctx:fillRect(0, 0, w, h)
        ctx.fillStyle = _fs
    end

    local canvas = code_div:querySelector("canvas")
    if is_none(canvas) then
        canvas = document:createElement("canvas")
        canvas.width = 400
        canvas.height = 400
        code_div:append(canvas)
        ctx = canvas:getContext("2d")
        _clear(ctx)
    end
    ctx = code_div:querySelector("canvas"):getContext("2d")
    local r = canvas:getBoundingClientRect()
    mx = (mouse.x - r.x) * canvas.width / r.width
    my = (mouse.y - r.y) * canvas.height / r.height
    clear = function() _clear(ctx) end
end

function run_script(code_edit)
    local code_div = code_edit.parentNode
    local code_val = code_edit.value
    set_locals(code_div)
    ---@diagnostic disable-next-line: assign-type-mismatch
    loop = nil
    ---@diagnostic disable-next-line: undefined-global
    local fn, load_err = load(code_val, "code-edit", "t", _ENV)
    if not fn then error(load_err) end
    local ran_ok, run_err = pcall(fn)
    if not ran_ok then error(run_err) end
    code_div.loop = loop
    -- todo: display error next to code
end

local function draw_play()
    local w, h = ctx.canvas.width, ctx.canvas.height
    ctx:save()
    ctx.fillStyle = "rgb(128 128 128 / 30%)"
    ctx:fillRect(0, 0, w, h)

    local cx, cy = w / 2, h / 2
    local r = math.min(w, h) * 0.1
    ctx:beginPath()
    ctx.fillStyle = "rgb(255 255 255 / 90%)"
    ctx:arc(cx, cy, r * 1.2, 0, math.pi * 2)
    ctx:fill()

    ctx:beginPath()
    ctx.fillStyle = "#222"
    ctx:moveTo(cx - r * 0.4, cy - r * 0.6)
    ctx:lineTo(cx - r * 0.4, cy + r * 0.6)
    ctx:lineTo(cx + r * 0.7, cy)
    ctx:closePath()
    ctx:fill()
    ctx:restore()
end

local function pause_rect()
    local size, pad = 40, 10
    local x = ctx.canvas.width - size - pad
    return x, pad, size, size
end

local function draw_pause(alpha)
    local x, y, w, h = pause_rect()
    ctx:save()
    ctx.fillStyle = "rgb(0 0 0 / " .. 100 * alpha .. "%)"
    ctx:fillRect(x, y, w, h)
    ctx.fillStyle = "rgb(255 255 255 / " .. 100 * alpha .. "%)"
    ctx:translate(x, y)
    local bar_w, gap = 6, 6
    local bx = (w - gap) / 2 - bar_w
    local by, bh = 8, h - 16
    ctx:fillRect(bx, by, bar_w, bh)
    ctx:fillRect(bx + bar_w + gap, by, bar_w, bh)
    ctx:restore()
end

local function is_hovered(elt)
    local r = elt:getBoundingClientRect()
    return (
        mouse.x >= r.x and mouse.x <= r.x + r.width
        and mouse.y >= r.y and mouse.y <= r.y + r.height
    )
end

local function pause_hovered()
    local rx, ry, rw, rh = pause_rect()
    return mx >= rx and mx <= rx + rw and my >= ry and my <= ry + rh
end

local function pause_code(code_div)
    code_div.paused = true
    code_div.pause_alpha = 0
    draw_play()
end

local function setup_play_pause(code_div)
    set_locals(code_div)
    pause_code(code_div)

    local canvas = code_div:querySelector("canvas")
    canvas:addEventListener("pointerdown", function(_, e)
        if not e.isPrimary then return end
        mouse.x = e.clientX
        mouse.y = e.clientY

        if code_div.paused then
            code_div.paused = false
            return
        end

        set_locals(code_div)
        if pause_hovered() then
            pause_code(code_div)
            e:preventDefault()
            e:stopPropagation()
        end
    end)
end

function fix_line_numbers()
    local slides = document:querySelector(".slides")
    local _tf = slides.style.transform
    local _sx, _sy = window.scrollX, window.scrollY
    slides.style.transform = "scale(1)"
    for _, pre in pairs(document:querySelectorAll(
        ".code-div pre.line-numbers"
    )) do window.Prism.plugins.lineNumbers:resize(pre) end
    slides.style.transform = _tf
    window:scroll(_sx, _sy)
end

function load_editors()
    window.Prism.plugins.toolbar:registerButton("run", js_obj {
        text = "run",
        onClick = function(_, env)
            local code_div = (
                env.element.parentNode.parentNode.parentNode
            )
            local code_edit = code_div:querySelector("textarea")
            code_div.paused = false
            run_script(code_edit)
        end,
    })
    window.Prism.plugins.toolbar:registerButton("reset", js_obj {
        text = "reset",
        onClick = function(_, env)
            local code_div = (
                env.element.parentNode.parentNode.parentNode
            )
            local code_edit = code_div:querySelector("textarea")
            code_edit.value = code_div.initial_code
            code_edit:oninput()

            code_div.paused = false
            set_locals(code_div)
            clear()
            run_script(code_edit)

            -- todo: let ctrl+z undo text reset
        end,
    })

    -- default copy includes nbsp, copy from code_edit instead
    local function override_copy(e)
        local btn = e.target:closest(
            "button.copy-to-clipboard-button"
        )
        if is_none(btn) then return end

        e:preventDefault()
        e:stopImmediatePropagation()
        local code_edit = (
            btn:closest(".code-div"):querySelector("textarea")
        )
        window.navigator.clipboard:writeText(code_edit.value)
    end
    document:addEventListener("click", function(_, e)
        pcall(override_copy, e)
    end, true)

    local title = document:querySelector("#title")
    local title_text = trim(title.innerHTML)
    local title_i = 0
    local function title_append()
        title.innerHTML = title_text:sub(1, title_i)
        title_i = title_i + 1
        if title_i <= #title_text then
            window:setTimeout(title_append, rng(20, 100))
        end
    end
    title_append()


    -- make full details box clickable
    for _, det in pairs(document:querySelectorAll("details")) do
        det:addEventListener("click", function(this)
            this:toggleAttribute("open")
        end)
        -- prevent double toggle and toggling on code click
        for _, c in pairs(det.children) do
            c:addEventListener("click", function(_, e)
                e:stopPropagation()
            end)
        end
    end

    -- set up .code-div editors & highlighters
    for _, scr_hl in pairs(document:querySelectorAll(
        ".code-div > script[type='text/plain']"
    )) do
        local code_div = scr_hl.parentNode
        local code_edit = code_div:querySelector("textarea")
        code_edit.spellcheck = false

        -- save code for reset button
        scr_hl.innerHTML = trim(scr_hl.innerHTML)
        code_div.initial_code = scr_hl.innerHTML
        -- set editor if not loaded with modified value
        if code_edit.value == "" then
            code_edit.value = code_div.initial_code
        end

        run_script(code_edit)
        setup_play_pause(code_div)

        -- add editor events

        function code_edit:onscroll()
            local pre = code_div:querySelector("pre")
            pre.scrollTop = code_edit.scrollTop
            pre.scrollLeft = code_edit.scrollLeft
        end

        function code_edit:oninput()
            local text = code_edit.value
            local code_hl = code_div:querySelector("code")
            if is_none(code_hl) then
                code_hl = code_div:querySelector(
                    "script[type='text/plain']"
                )
            end
            text = text:gsub("&", "&amp;"):gsub("<", "&lt;")
            if code_hl.tagName == "CODE" then
                text = "&#8203;" .. text .. "&#8203;"
            end
            code_hl.innerHTML = text
            window.Prism:highlightElement(code_hl)
            code_edit:onscroll()
            fix_line_numbers()
        end

        -- first call converts script to pre>code,
        -- 2nd pads with zero-width space to prevent auto-trimming
        -- (from browser, not just normalize-whitespace extension)
        code_edit:oninput()
        code_edit:oninput()

        function code_edit:onkeydown(event)
            local text = code_edit.value
            if event.key == "Tab" then
                event:preventDefault()
                local sel_start = code_edit.selectionStart
                local sel_end = code_edit.selectionEnd
                local before_tab = text:sub(1, sel_start)
                local after_tab = text:sub(sel_end + 1)
                local cursor_pos = sel_start + 1

                -- todo: indent if line(s) selected

                -- shift tab (todo: de-indent, not just delete tab)
                if event.shiftKey then
                    if before_tab:sub(-1) == "\t" then
                        code_edit.value = (
                            before_tab:sub(1, -2) .. after_tab
                        )
                        cursor_pos = sel_start - 1
                        code_edit.selectionStart = cursor_pos
                        code_edit.selectionEnd = cursor_pos
                        code_edit:oninput()
                    end
                    return
                end

                -- regular tab
                code_edit.value = before_tab .. "\t" .. after_tab
                -- move cursor
                code_edit.selectionStart = cursor_pos
                code_edit.selectionEnd = cursor_pos
                code_edit:oninput()
            elseif event.key == "Enter" and event.ctrlKey then
                code_div.paused = false
                run_script(code_edit)
            end
        end
    end

    local function in_view(elt)
        local r = elt:getBoundingClientRect()
        return r.bottom > 0 and r.top < window.innerHeight
    end

    -- call each loop function
    local last_frame_time = window.performance:now()
    local function big_loop()
        local now = window.performance:now()
        local dt = (now - last_frame_time) / 1000
        last_frame_time = now

        local code_divs = document:querySelectorAll(".code-div")
        for i = 0, code_divs.length - 1 do
            local code_div = code_divs[i]
            set_locals(code_div)
            local canvas = code_div:querySelector("canvas")
            if not code_div.paused and not in_view(canvas) then
                pause_code(code_div)
            end

            local canv_hovered = is_hovered(canvas)
            if code_div.paused then
                canvas.style.cursor = (
                    canv_hovered and "pointer" or "default"
                )
            else
                if code_div.loop then code_div.loop(dt) end

                code_div.pause_alpha = fri_lerp(
                    code_div.pause_alpha,
                    canv_hovered and 1 or 0,
                    0.1, dt
                )
                draw_pause(code_div.pause_alpha)
                canvas.style.cursor = (
                    pause_hovered() and "pointer" or "default"
                )
            end
        end
        window:requestAnimationFrame(big_loop)
    end
    big_loop()
end
