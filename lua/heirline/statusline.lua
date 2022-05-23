local utils = require("heirline.utils")
local hi = require("heirline.highlights")

local default_restrict = {
    stop_when = true,
    init = true,
    provider = true,
    condition = true,
    restrict = true,
    pick_child = true,
}

local StatusLine = {
    hl = {},
    merged_hl = {},
}

function StatusLine:new(child, index)
    child = child or {}
    local new = {}

    if type(child.hl) == "function" then
        new.hl = child.hl
    elseif type(child.hl) == "table" then
        new.hl = vim.tbl_extend("keep", child.hl, {})
    end

    new.condition = child.condition
    new.pick_child = child.pick_child and vim.tbl_exend("keep", child.pick_child, {})
    new.init = child.init
    new.provider = child.provider
    new.stop_when = child.stop_when
    new.restrict = child.restrict and vim.tbl_extend("keep", child.restrict, {})

    if child.static then
        for k, v in pairs(vim.tbl_deep_extend("keep", child.static, {})) do
            new[k] = v
        end
    end

    local restrict = vim.tbl_extend("force", default_restrict, self.restrict or {})
    setmetatable(new, self)
    self.__index = function(t, v)
        if restrict[v] then
            return nil
        else
            return self[v]
        end
    end

    local parent_id = self.id or {}
    new.id = vim.tbl_extend("force", parent_id, { [#parent_id + 1] = index })

    for i, sub in ipairs(child) do
        new[i] = new:new(sub, i)
    end

    return new
end

function StatusLine:broadcast(func)
    for i, c in ipairs(self) do
        func(c)
        c:broadcast(func)
    end
end

function StatusLine:find(func)
    if func(self) then
        return self
    end
    for i, c in ipairs(self) do
        local res = c:find(func)
        if res then
            return res
        end
    end
end

function StatusLine:get(id)
    id = id or {}
    local curr = self
    for _, i in ipairs(id) do
        curr = curr[i]
    end
    return curr
end

function StatusLine:nonlocal(attr)
    return getmetatable(self).__index(self, attr)
end

function StatusLine:local_(attr)
    local orig_mt = getmetatable(self)
    setmetatable(self, {})
    local result = self[attr]
    setmetatable(self, orig_mt)
    return result
end

function StatusLine:set_win_attr(attr, val, default)
    local winnr = self.winnr
    self[attr] = self[attr] or {}
    self[attr][winnr] = val or (self[attr][winnr] or default)
end

function StatusLine:get_win_attr(attr, default)
    local winnr = self.winnr
    self[attr] = self[attr] or {}
    self[attr][winnr] = self[attr][winnr] or default
    return self[attr][winnr]
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
    local parent_hl = self:nonlocal("merged_hl")

    if parent_hl.force then
        self.merged_hl = vim.tbl_extend("keep", parent_hl, hl)
    else
        self.merged_hl = vim.tbl_extend("force", parent_hl, hl)
    end

    if self.provider then
        local provider_str = type(self.provider) == "function" and (self:provider() or "") or (self.provider or "")
        local hl_str_start, hl_str_end = hi.eval_hl(self.merged_hl)
        table.insert(stl, hl_str_start .. provider_str .. hl_str_end)
    end

    local children_i
    if self.pick_child then
        children_i = self.pick_child
    else
        children_i = {}
        for i, _ in ipairs(self) do
            table.insert(children_i, i)
        end
    end

    for _, i in ipairs(children_i) do
        local child = self[i]
        local out = child:eval()
        table.insert(stl, out)
    end

    self.stl = table.concat(stl, "")

    return self.stl
end

return StatusLine
