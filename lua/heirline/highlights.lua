local M = {}

M.defined_highlights = {}

function M.make_hl(hl_name, hl)
    vim.api.nvim_set_hl(0, hl_name, hl)
end

function M.reset_highlights()
    M.defined_highlights = {}
end

function M.name_hl(hl)
    local style = vim.tbl_filter(function(value)
        return not vim.tbl_contains({ "background", "bg", "foreground", "fg", "special", "sp" }, value)
    end, vim.tbl_keys(hl))
    return "Stl"
        .. (hl.foreground and hl.foreground:gsub("#", "") or "_")
        .. (hl.background and hl.background:gsub("#", "") or "_")
        .. table.concat(style, "")
        .. (hl.special and hl.special:gsub(",", "") or "")
end

local function hex(n)
    if n and type(n) == "number" then
        return string.format("#%06x", n)
    end
end

local function fixhl(hl)
    local fixed_hl = vim.tbl_extend("force", hl, {})
    fixed_hl.foreground = hex(hl.foreground or hl.fg)
    fixed_hl.background = hex(hl.background or hl.bg)
    fixed_hl.special = hex(hl.special or hl.sp or hl.guisp)
    fixed_hl.guisp = nil
    fixed_hl.force = nil

    if hl.style then
        for _, val in ipairs(vim.fn.split(hl.style, ",")) do
            fixed_hl[val] = true
        end
        fixed_hl.style = nil
    end
    return fixed_hl
end

function M.eval_hl(hl)
    if vim.tbl_isempty(hl) then
        return "", ""
    end
    hl = fixhl(hl)
    local hl_name = M.name_hl(hl)
    if not M.defined_highlights[hl_name] then
        M.make_hl(hl_name, hl)
        M.defined_highlights[hl_name] = true
    end
    return "%#" .. hl_name .. "#", "%*"
end

return M
