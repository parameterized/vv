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

function is_none(v)
    return v == nil or v == js.null or v == js.undefined
end

unpack = table.unpack

function trim(s)
    return s:match("^[%s\r\n\t]*(.-)[%s\r\n\t]*$")
end
