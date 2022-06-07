local M = {}

local defined_highlights = {}

local loaded_colors = {}

function M.reset_highlights()
    defined_highlights = {}
end

function M.load_colors(colors)
    for c, v in pairs(colors) do
        loaded_colors[c] = v
    end
end

function M.clear_colors()
    loaded_colors = {}
end

function M.get_loaded_colors()
    return vim.tbl_extend("force", loaded_colors, {})
end

function M.get_highlights()
    return vim.tbl_extend("force", defined_highlights, {})
end

local function make_hl(hl_name, hl)
    vim.api.nvim_set_hl(0, hl_name, hl)
end

local function name_rgb_hl(hl)
    local style = vim.tbl_filter(function(value)
        return not vim.tbl_contains({ "bg", "fg", "sp", "ctermbg", "ctermfg", "cterm" }, value)
    end, vim.tbl_keys(hl))
    return "Stl"
        .. (hl.fg and hl.fg:gsub("#", "") or "")
        .. "_"
        .. (hl.bg and hl.bg:gsub("#", "") or "")
        .. "_"
        .. table.concat(style, "")
        .. "_"
        .. (hl.sp and hl.sp:gsub("#", "") or "")
end

local function name_cterm_hl(hl)
    local style = vim.tbl_filter(function(value)
        return not vim.tbl_contains({ "bg", "fg", "sp", "ctermbg", "ctermfg", "cterm" }, value)
    end, vim.tbl_keys(hl.cterm or hl))
    return "Stl" .. (hl.ctermfg or "") .. "_" .. (hl.ctermbg or "") .. "_" .. table.concat(style, "")
end

local function hex(val)
    if type(val) == "number" then
        return string.format("#%06x", val)
    else
        return val
    end
end

local function get_color(val)
    if type(val) == "string" then
        return loaded_colors[val] or val
    else
        return val
    end
end

local function normalize_hl(hl)
    local fixed_hl = vim.tbl_extend("force", hl, {})
    fixed_hl.fg = hex(get_color(hl.fg or hl.foreground))
    fixed_hl.bg = hex(get_color(hl.bg or hl.background))
    fixed_hl.sp = hex(get_color(hl.sp or hl.special))
    fixed_hl.ctermfg = get_color(hl.ctermfg)
    fixed_hl.ctermbg = get_color(hl.ctermbg)
    fixed_hl.force = nil
    return fixed_hl
end

local name_hl = vim.o.termguicolors and name_rgb_hl or name_cterm_hl
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
