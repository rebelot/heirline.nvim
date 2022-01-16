local M = {}

function M.get_highlight(hlname)
    local hl = vim.api.nvim_get_hl_by_name(hlname, true)
    local t = {}
    local hex = function(n)
        if n then
			return vim.fn.printf("#%06x", n)
        end
    end
    t.fg = hex(hl.foreground)
    t.bg = hex(hl.background)
    t.sp = hex(hl.special)
    t.style = "none,"
    if hl.underline then
        t.style = t.style .. "underline"
    end
    if hl.undercurl then
        t.style = t.style .. "undercurl"
    end
    if hl.bold then
        t.style = t.style .. "bold"
    end
    if hl.italic then
        t.style = t.style .. "italic"
    end
    if hl.reverse then
        t.style = t.style .. "reverse"
    end
    if hl.nocombine then
        t.style = t.style .. "nocombine"
    end
    return t
end

function M.clone(block, with)
    return vim.tbl_deep_extend("force", block, with or {})
end

function M.surround(delimiters, color, component)
    component = M.clone(component)
    component.hl = component.hl or {}
    if type(component.hl) == "function" then
        local old_hl_func = component.hl
        component.hl = function(obj)
            local hl = old_hl_func(obj)
            hl.bg = color
            return hl
        end
    else
        component.hl.bg = color
    end
    return {
        {
            provider = delimiters[1],
            hl = { fg = color },
        },
        component,
        {
            provider = delimiters[2],
            hl = { fg = color },
        },
    }
end

function M.insert(destination, ...)
    local children = { ... }
    local new = M.clone(destination)
    for i, child in ipairs(children) do
        local new_child = M.clone(child)
        table.insert(new, new_child)
    end
    return new
end

return M
