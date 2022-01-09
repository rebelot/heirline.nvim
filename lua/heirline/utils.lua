local M = {}

function M.get_highlight(hlname)
    local hl = vim.api.nvim_get_hl_by_name(hlname, true)
    local t = {}
    local hex = function(n)
        if n then
            return string.format("#%x", n) end
        end
    t.fg = hex(hl.foreground)
    t.bg = hex(hl.background)
    t.sp = hex(hl.special)
    t.style = 'none,'
    if hl.underline then t.style = t.style.. "underline" end
    if hl.undercurl then t.style = t.style.. "undercurl" end
    if hl.bold then t.style = t.style.. "bold" end
    if hl.italic then t.style = t.style.. "italic" end
    if hl.reverse then t.style = t.style.. "reverse" end
    if hl.nocombine then t.style = t.style.. "nocombine" end
    return t
end

function M.clone(block, with)
    return vim.tbl_deep_extend("force", block, with or {})
end

function M.surround(delimiters, color, wrapped)
    wrapped = M.clone(wrapped)
    wrapped.hl = wrapped.hl or {}
    if type(wrapped.hl) == 'function' then
        local old_hl_func = wrapped.hl
        wrapped.hl = function(self)
            local hl = old_hl_func(self)
            hl.bg = color
            return hl
        end
    else
        wrapped.hl.bg = color
    end
    return {
        {
            provider = delimiters[1],
            hl = { fg = color }
        },
        wrapped,
        {
            provider = delimiters[2],
            hl = { fg = color }
        },

    }
end
return M
