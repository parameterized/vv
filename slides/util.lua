---@diagnostic disable: lowercase-global

js = require "js"
window = js.global
document = window.document

function js_obj(o)
    local jso = js.new(window.Object)
    for k, v in pairs(o) do
        jso[k] = v
    end
    return jso
end

function js_arr(...)
    return js.new(window.Array, ...)
end
