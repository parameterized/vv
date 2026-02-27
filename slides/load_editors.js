const mouse = {
    x: 0, y: 0,
    held: { 0: false, 1: false, 2: false },
}
function mouse_held(button) {
    if (button === undefined) {
        for (const b in mouse.held) {
            if (mouse.held[b]) {
                return true
            }
        }
        return false
    }
    return button in mouse.held && mouse.held[button]
}
onpointermove = e => {
    if (!e.isPrimary) return
    mouse.x = e.clientX
    mouse.y = e.clientY
}
onpointerdown = e => {
    if (!e.isPrimary) return
    if (e.button in mouse.held) {
        mouse.held[e.button] = true
    }
    mouse.x = e.clientX
    mouse.y = e.clientY
}
onpointerup = e => {
    if (!e.isPrimary) return
    if (e.button in mouse.held) {
        mouse.held[e.button] = false
    }
}

function rng(a, b) {
    const arr = new Uint32Array(1)
    crypto.getRandomValues(arr)
    const v = arr[0] / 0xffffffff
    if (a === undefined) return v
    if (b === undefined) return v * a
    return a + v * (b - a)
}

function set_locals(code_div) {
    // set ctx, bounds, mx, my, clear

    if (code_div === undefined) {
        code_div = document.currentScript.parentNode
    }
    const _clear = ctx => {
        const _fs = ctx.fillStyle
        ctx.fillStyle = "#222"
        ctx.fillRect(0, 0, 300, 300)
        ctx.fillStyle = _fs
    }
    let canvas = code_div.querySelector("canvas")
    if (canvas === null) {
        canvas = document.createElement("canvas")
        canvas.width = canvas.height = "300"
        code_div.append(canvas)
        ctx = canvas.getContext("2d")
        _clear(ctx)
    }
    ctx = code_div.querySelector("canvas").getContext("2d")
    bounds = ctx.canvas.getBoundingClientRect()
    mx = mouse.x - bounds.x
    my = mouse.y - bounds.y
    clear = () => _clear(ctx)
}

function run_script(code_edit) {
    try {
        let code_div, code_val
        if (code_edit) {
            code_div = code_edit.parentNode
            code_val = code_edit.value
        } else {
            code_div = document.currentScript.parentNode
            code_val = document.currentScript.innerHTML
        }
        set_locals(code_div)
        loop = null
        eval(code_val)
        code_div.loop = loop
    }
    catch (err) { console.error(err) }
    // todo: display error next to code
}


function fix_line_numbers() {
    const slides = document.querySelector(".slides")
    const _tf = slides.style.transform
    slides.style.transform = "scale(1)"
    for (const pre of document.querySelectorAll(
        ".code-div pre.line-numbers"
    )) Prism.plugins.lineNumbers.resize(pre)
    slides.style.transform = _tf
}

function load_editors() {
    Prism.plugins.toolbar.registerButton("run", {
        text: "run",
        onClick: env => run_script(
            env.element.parentNode.parentNode.parentNode
            .querySelector("textarea")
        ),
    })
    Prism.plugins.toolbar.registerButton("reset", {
        text: "reset",
        onClick: env => {
            const code_div = env.element.parentNode.parentNode.parentNode
            const code_edit = code_div.querySelector("textarea")
            code_edit.value = code_div.initial_code
            code_edit.oninput()
            const ctx = code_div.querySelector("canvas").getContext("2d")
            ctx.fillStyle = "#222"
            ctx.fillRect(0, 0, 300, 300)
            run_script(code_edit)
            // todo: let ctrl+z undo this
        },
    })


    const title = document.querySelector("#title")
    const title_text = title.innerHTML.trim()
    let title_i = 0
    const title_append = () => {
        title.innerHTML = title_text.slice(0, title_i++)
        if (title_i <= title_text.length) {
            setTimeout(title_append, rng(20, 100))
        }
    }
    title_append()


    // make full details box clickable
    for (const det of document.querySelectorAll("details")) {
        det.addEventListener("click", function() {
            this.toggleAttribute("open")
        })
        // prevent double toggle and toggling on code click
        for (const c of det.children) {
            c.addEventListener("click", e => e.stopPropagation())
        }
    }

    // set up .code-div editors & highlighters
    for (const scr_hl of document.querySelectorAll(
        ".code-div > script[type='text/plain']"
    )) {
        const code_div = scr_hl.parentNode
        const code_edit = code_div.querySelector("textarea")
        code_edit.spellcheck = false

        // save code for reset button
        scr_hl.innerHTML = scr_hl.innerHTML.trim()
        code_div.initial_code = scr_hl.innerHTML
        // set editor if not loaded with modified value
        if (!code_edit.value)
        { code_edit.value = code_div.initial_code }

        run_script(code_edit)

        // add editor events

        code_edit.onscroll = () => {
            const pre = code_div.querySelector("pre") 
            pre.scrollTop = code_edit.scrollTop
            pre.scrollLeft = code_edit.scrollLeft
        }

        code_edit.oninput = () => {
            let text = code_edit.value
            const code_hl = (
                code_div.querySelector("code")
                || code_div.querySelector("script[type='text/plain']")
            )
            text = (
                text.replace(new RegExp("&", "g"), "&amp;")
                .replace(new RegExp("<", "g"), "&lt;")
            )
            if (code_hl.tagName === "CODE") {
                text = `&#8203;${text}&#8203;`
            }
            code_hl.innerHTML = text
            Prism.highlightElement(code_hl)
            code_edit.onscroll()
            fix_line_numbers()
        }
        // first call converts script to pre>code,
        // 2nd pads with zero-width space to prevent auto-trimming
        // (from browser, not just normalize-whitespace extension)
        code_edit.oninput()
        code_edit.oninput()

        code_edit.onkeydown = event => {
            const text = code_edit.value
            if (event.key === "Tab") {
                event.preventDefault()
                let before_tab = text.slice(0, code_edit.selectionStart)
                let after_tab = text.slice(
                    code_edit.selectionEnd,
                    code_edit.value.length
                )
                let cursor_pos = code_edit.selectionStart + 1

                // todo: indent if line(s) selected

                // shift tab (todo: de-indent, not just delete tab)
                console.log(before_tab)
                if (event.shiftKey) {
                    if (before_tab.endsWith("\t")) {
                        code_edit.value = (
                            before_tab.slice(0, -1) + after_tab
                        )
                        cursor_pos = before_tab.length - 1
                        code_edit.selectionStart = cursor_pos
                        code_edit.selectionEnd = cursor_pos
                        code_edit.oninput()
                    }
                    return
                }

                // regular tab
                code_edit.value = before_tab + "\t" + after_tab
                // move cursor
                code_edit.selectionStart = cursor_pos
                code_edit.selectionEnd = cursor_pos
                code_edit.oninput()
            } else if (event.key === "Enter" && event.ctrlKey) {
                // todo: check if run button enabled
                run_script(code_edit)
            }
        }
    }

    // call each loop function
    let last_frame_time = performance.now()
    function big_loop() {
        const dt = (performance.now() - last_frame_time) / 1000
        last_frame_time = performance.now()

        for (const code_div of document.querySelectorAll(".code-div")) {
            set_locals(code_div)
            if (code_div.loop) code_div.loop(dt)
        }
        requestAnimationFrame(big_loop)
    }
    big_loop()
}
