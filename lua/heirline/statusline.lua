local utils = require("heirline.utils")
local hi = require("heirline.highlights")

local default_restrict = {
    stop_at_first = true,
    init = true,
    provider = true,
    condition = true,
    restrict = true,
}

local StatusLine = {
    hl = {},
    cur_hl = {},
}

function StatusLine:new(child)
    child = child or {}
    local new = {}

    if type(child.hl) == "function" then
        new.hl = child.hl
    elseif type(child.hl) == "table" then
        new.hl = vim.tbl_extend("keep", child.hl, {})
    end

    new.condition = child.condition
    new.init = child.init
    new.provider = child.provider
    new.stop_at_first = child.stop_at_first
    new.restrict = child.restrict and vim.tbl_extend("keep", child.restrict, {})

    if child.static then
        for k, v in pairs(vim.tbl_deep_extend("keep", child.static, {})) do
            new[k] = v
        end
    end

    local restrict = vim.tbl_extend("force", default_restrict, new.restrict or {})
    setmetatable(new, self)
    self.__index = function(t, v)
        if restrict[v] then
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

    local hl = type(self.hl) == "function" and (self:hl() or {}) or self.hl -- self raw hl
    local prev_hl = getmetatable(self).__index(self, "cur_hl") -- the parent hl

    if prev_hl.force then
        self.cur_hl = vim.tbl_extend("keep", prev_hl, hl) -- merged hl
    else
        self.cur_hl = vim.tbl_extend("force", prev_hl, hl) -- merged hl
    end

    if self.provider then
        local provider_str = type(self.provider) == "function" and (self:provider() or "") or (self.provider or "")
        local hl_str_start, hl_str_end = hi.eval_hl(self.cur_hl)
        table.insert(stl, hl_str_start .. provider_str .. hl_str_end)
    end

    for _, child in ipairs(self) do
        local out = child:eval()
        table.insert(stl, out)
        if self.stop_at_first and out ~= "" then
            break
        end
    end


    return table.concat(stl, "")
end

return StatusLine
