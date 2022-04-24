local M = {}

local defined_highlights = {}

function M.reset_highlights()
    defined_highlights = {}
end

function M.get_highlights()
    return vim.tbl_extend("force", defined_highlights, {})
end

local function make_hl(hl_name, hl)
    vim.api.nvim_set_hl(0, hl_name, hl)
end

local function name_hl(hl)
    local style = vim.tbl_filter(function(value)
        return not vim.tbl_contains({ "background", "foreground", "special" }, value)
    end, vim.tbl_keys(hl))
    return "Stl"
        .. (hl.foreground and hl.foreground:gsub("#", "") or "_")
        .. (hl.background and hl.background:gsub("#", "") or "_")
        .. table.concat(style, "")
        .. (hl.special and hl.special:gsub(",", "") or "")
end

local function hex(val)
    if type(val) == "number" then
        return string.format("#%06x", val)
    else
        return val
    end
end

local function normalize_hl(hl)
    local fixed_hl = vim.tbl_extend("force", hl, {})
    fixed_hl.foreground = hex(hl.foreground or hl.fg)
    fixed_hl.background = hex(hl.background or hl.bg)
    fixed_hl.special = hex(hl.special or hl.sp or hl.guisp)
    fixed_hl.guisp = nil
    fixed_hl.fg = nil
    fixed_hl.bg = nil
    fixed_hl.sp = nil
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
    hl = normalize_hl(hl)
    local hl_name = name_hl(hl)
    if not defined_highlights[hl_name] then
        make_hl(hl_name, hl)
        defined_highlights[hl_name] = true
    end
    return "%#" .. hl_name .. "#", "%*"
end

return M
