local M = {}
local str_format = string.format
local tbl_insert = table.insert
local tbl_concat = table.concat

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

local function get_hl_style(hl)
    local style = {}
    local valid_styles = {
        "bold",
        "standout",
        "underline",
        "undercurl",
        "underdouble",
        "underdotted",
        "underdashed",
        "strikethrough",
        "italic",
        "reverse",
    }
    for _, v in ipairs(valid_styles) do
        if hl[v] then
            tbl_insert(style, v)
        end
    end
    return tbl_concat(style, "")
end

local function name_rgb_hl(hl)
    local hl_name, _ =
    str_format("Stl%s_%s_%s_%s", hl.fg or "", hl.bg or "", get_hl_style(hl), hl.sp or ""):gsub("#", "")
    return hl_name
end

local function name_cterm_hl(hl)
    return str_format("Stl%s_%s_%s", (hl.ctermfg or ""), (hl.ctermbg or ""), get_hl_style(hl.cterm or hl))
end

local function hex(val)
    if type(val) == "number" then
        return str_format("#%06x", val)
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

function M.eval_hl(hl)
    if vim.tbl_isempty(hl) or hl[true] then
        return "", ""
    end
    hl = normalize_hl(hl)
    local name_hl = vim.o.termguicolors and name_rgb_hl or name_cterm_hl
    local hl_name = name_hl(hl)
    if not defined_highlights[hl_name] then
        make_hl(hl_name, hl)
        defined_highlights[hl_name] = true
    end
    return "%#" .. hl_name .. "#", "%*"
end

return M
