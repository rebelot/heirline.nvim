local utils = require("heirline.utils")
local defined_highlights = {}

local function make_hl(hl_name, hl)
    local fg = hl.fg and "guifg=" .. hl.fg .. " " or ""
    local bg = hl.bg and "guibg=" .. hl.bg .. " " or ""
    local style = hl.style and "gui=" .. hl.style .. " " or ""
    local guisp = hl.guisp and "guisp=" .. hl.guisp .. " " or ""
    if fg or bg or style or guisp then
        vim.cmd("highlight " .. hl_name .. " " .. fg .. bg .. style .. guisp)
    end
    defined_highlights[hl_name] = true
end

local function name_hl(hl)
    return "Stl"
        .. (hl.fg and hl.fg:gsub("#", "") or "")
        .. (hl.bg and hl.bg:gsub("#", "") or "")
        .. (hl.style and hl.style:gsub(",", "") or "")
        .. (hl.guisp and hl.guisp:gsub(",", "") or "")
end

local function eval_hl(hl)
    local hl_name = name_hl(hl)
    if not defined_highlights[hl_name] then
        make_hl(hl_name, hl)
    end
    return "%#" .. hl_name .. "#", "" --"%*"
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
        local hl_str_start, hl_str_end = eval_hl(self.cur_hl)
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

return StatusLine
