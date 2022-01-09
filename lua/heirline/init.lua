local M = {}
local utils = require("heirline.utils")

M.defined_highlights = {}
M.statusline = {}

function M.eval_hl(hl)
    hl = M.hl_with_name(hl)
    if not M.defined_highlights[hl.name] then
        M.make_hl(hl)
    end
    return "%#" .. hl.name .. "#", "" --"%*"
end

function M.make_hl(hl)
    if hl.link then
        vim.cmd("highlight! link " .. hl.name .. " " .. hl.link)
    else
        local fg = hl.fg and "guifg=" .. hl.fg .. " " or ""
        local bg = hl.bg and "guibg=" .. hl.bg .. " " or ""
        local style = hl.style and "gui=" .. hl.style .. " " or ""
        local guisp = hl.guisp and "guisp=" .. hl.guisp .. " " or ""
        if fg or bg or style or guisp then
            vim.cmd("highlight " .. hl.name .. " " .. fg .. bg .. style .. guisp)
        end
    end
    M.defined_highlights[hl.name] = true
end

function M.name_hl(hl)
    return "Stl"
        .. (hl.fg and hl.fg:gsub("#", "") or "")
        .. (hl.bg and hl.bg:gsub("#", "") or "")
        .. (hl.style and hl.style:gsub(",", "") or "")
        .. (hl.guisp and hl.guisp:gsub(",", "") or "")
end

function M.hl_with_name(hl)
    return vim.tbl_extend('force', hl, {name = M.name_hl(hl)})
end

function M.load()
    vim.g.qf_disable_statusline = true
    vim.cmd("set statusline=%{%v:lua.require'heirline'.eval()%}")
end

function M.setup(config)
    M.statusline = M.StatusLine:new(config.statuslines)
    M.load()
end

function M.eval()
    return M.statusline:eval()
end

local StatusLine = {
    hl = { fg = utils.get_highlight("StatusLine").fg, bg = utils.get_highlight("StatusLine").bg },
    cur_hl = {},
}

function StatusLine:new(child)
    child = child or {}
    local new = {}
    new.hl = child.hl
    new.condition = child.condition
    new.init = child.init
    new.provider = child.provider
    new.stop = child.stop
    setmetatable(new, self)
    self.__index = function(t, v)
        if v == "stop" then
            return nil
        else
            return self[v]
        end
    end
    for i, sub in ipairs(child) do
        new[i] = new:new(sub)
    end
    return new
end

function StatusLine:eval()
    if self.condition and not self:condition() then
        return ""
    end

    if self.init then
        self:init()
    end

    local stl = {}

    local hl = type(self.hl) == "function" and self:hl() or self.hl -- table
    self.cur_hl = vim.tbl_extend("force", self.cur_hl, hl) -- table

    if self.provider then
        local provider_str = type(self.provider) == "function" and (self:provider() or "") or (self.provider or "")
        local hl_str_start, hl_str_end = M.eval_hl(self.cur_hl)
        table.insert(stl, hl_str_start .. provider_str .. hl_str_end)
    end

    for i, child in ipairs(self) do
        local out = child:eval()
        table.insert(stl, out)
        if self.stop and out ~= "" then
            break
        end
    end

    return table.concat(stl, "")
end

M.StatusLine = StatusLine

return M
