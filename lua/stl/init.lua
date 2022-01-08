local M = {}
local utils = require("stl.utils")

M.defined_highlights = {}
M.statusline = {}

function M.eval_hl(hl)
    if vim.tbl_isempty(hl) then
        return "", ""
    else
        hl.name = hl.name
            or (
                "Stl"
                .. (hl.fg and hl.fg:gsub("#", "_") or "")
                .. (hl.bg and hl.bg:gsub("#", "_") or "")
                .. (hl.style and hl.style:gsub(",", "_") or "")
                .. (hl.guisp and hl.guisp:gsub(",", "_") or "")
            )
        if not M.defined_highlights[hl.name] then
            M.make_hl(hl)
        end
        return "%#" .. hl.name .. "#", "" --"%*"
    end
end

-- function M.eval_hl(hl)
--     if vim.tbl_isempty(hl) then
--         return "", ""
--     else
--         M.make_hl(hl)
--         return "%#" .. hl.name .. "#", "" --"%*"
--     end
-- end

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

--
-- function M.statusline()
--     for i, statusline in ipairs(M.statuslines) do
--         statusline.index = i
--         if statusline:condition() then
--             return M.eval(statusline)
--         end
--     end
-- end

function M.load()
    vim.cmd("set statusline=%{%v:lua.require'stl'.eval()%}")
end

function M.setup(config)
    M.statusline = M.StatusLine:new(config.statuslines)
    M.load()
end

function M.eval()
    return M.statusline:eval()
end

local StatusLine = {
    -- hl = { fg = utils.get_highlight("StatusLine").fg, bg = utils.get_highlight("StatusLine").bg, name = "StlDefault" },
    hl = { fg = utils.get_highlight("StatusLine").fg, bg = utils.get_highlight("StatusLine").bg },
    cur_hl = {},
}

function StatusLine:new(child)
    child = child or {}
    local new = {}
    new.hl = child.hl -- TODO: table highlights should be merged here and assigned their name
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

-- function StatusLine:new(child)
--     child = child or {}
--     setmetatable(child, self)
--     self.__index = self
--     for i, sub in ipairs(child) do
--         child:new(sub)
--     end
--     return child
-- end

function StatusLine:eval()
    local stl = {}

    if self.condition and not self:condition() then
        return ""
    end

    if self.init then
        self:init()
    end

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
