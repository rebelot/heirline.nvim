local M = {}

M.defined_highlights = {}

function M.make_hl(hl_name, hl)
    local fg = hl.fg and "guifg=" .. hl.fg .. " " or ""
    local bg = hl.bg and "guibg=" .. hl.bg .. " " or ""
    local style = hl.style and "gui=" .. hl.style .. " " or ""
    local guisp = hl.guisp and "guisp=" .. hl.guisp .. " " or ""
    if fg or bg or style or guisp then
        vim.cmd("highlight " .. hl_name .. " " .. fg .. bg .. style .. guisp)
    end
end

function M.reset_highlights()
    M.defined_highlights = {}
end

function M.name_hl(hl)
    return "Stl"
        .. (hl.fg and hl.fg:gsub("#", "") or "_")
        .. (hl.bg and hl.bg:gsub("#", "") or "_")
        .. (hl.style and hl.style:gsub(",", "") or "")
        .. (hl.guisp and hl.guisp:gsub(",", "") or "")
end

function M.eval_hl(hl)
    if vim.tbl_isempty(hl) then
        return "", ""
    end
    local hl_name = M.name_hl(hl)
    if not M.defined_highlights[hl_name] then
        M.make_hl(hl_name, hl)
        M.defined_highlights[hl_name] = true
    end
    return "%#" .. hl_name .. "#", "%*"
end

return M
