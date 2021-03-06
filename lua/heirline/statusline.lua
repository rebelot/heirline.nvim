local utils = require("heirline.utils")
local hi = require("heirline.highlights")

local default_restrict = {
    stop_when = true,
    init = true,
    provider = true,
    condition = true,
    restrict = true,
    pick_child = true,
    after = true,
    on_click = true,
    update = true,
    stl = true,
    _win_stl = true,
    _au_id = true,
}

---@class StatusLine
---@field condition? function
---@field init? function
---@field provider? function | string
---@field hl? function | table | string
---@field restrict? table
---@field after? function
---@field update? function | table
---@field on_click? function | table
---@field stl string
---@field id table<integer>
---@field winnr integer
---@field _win_stl? table
---@field _au_id? integer
---@field pick_child? table<integer>
local StatusLine = {
    hl = {},
    merged_hl = {},
}

---Initialize a new statusline object
---@param child table
---@param index? integer
---@return StatusLine
function StatusLine:new(child, index)
    child = child or {}
    local new = {}

    if child.hl then
        local hl_type = type(child.hl)
        if hl_type == "function" then
            new.hl = child.hl
        elseif hl_type == "table" then
            new.hl = vim.tbl_extend("keep", child.hl, {})
        elseif hl_type == "string" then
            new.hl = utils.get_highlight(child.hl)
        end
    end

    if child.update then
        local update_type = type(child.update)
        if vim.tbl_contains({ "function", "string" }, update_type) then
            new.update = child.update
        elseif update_type == "table" then
            new.update = vim.tbl_extend("keep", child.update, {})
        end
    end

    new.condition = child.condition
    new.pick_child = child.pick_child and vim.tbl_exend("keep", child.pick_child, {})
    new.init = child.init
    new.provider = child.provider
    new.stop_when = child.stop_when
    new.after = child.after
    new.on_click = child.on_click and vim.tbl_extend("keep", child.on_click, {})
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

--- Broadcast a function that will be executed by every component
---@param func function
function StatusLine:broadcast(func)
    for i, c in ipairs(self) do
        func(c)
        c:broadcast(func)
    end
end

--- Get the component where func(component) evaluates to true
---@param func function predicate
---@return StatusLine
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

--- Get the component with id == `id`
---@param id table<integer>
---@return StatusLine
function StatusLine:get(id)
    id = id or {}
    local curr = self
    for _, i in ipairs(id) do
        curr = curr[i]
    end
    return curr
end

--- Get attribute `attr` value from parent component
---@param attr string
---@return any
function StatusLine:nonlocal(attr)
    return getmetatable(self).__index(self, attr)
end

--- Get attribute `attr` value from component
---@param attr string
---@return any
function StatusLine:local_(attr)
    local orig_mt = getmetatable(self)
    setmetatable(self, {})
    local result = self[attr]
    setmetatable(self, orig_mt)
    return result
end

--- Set window-nr attribute
---@param attr string
---@param val any
---@param default any
function StatusLine:set_win_attr(attr, val, default)
    local winnr = self.winnr
    self[attr] = self[attr] or {}
    self[attr][winnr] = val or (self[attr][winnr] or default)
end

--- Get window-nr attribute
---@param attr string
---@param default any
---@return any
function StatusLine:get_win_attr(attr, default)
    local winnr = self.winnr
    self[attr] = self[attr] or {}
    self[attr][winnr] = self[attr][winnr] or default
    return self[attr][winnr]
end

---@param component StatusLine
---@return string
local function register_global_function(component)
    local on_click = component.on_click
    local winid = vim.api.nvim_get_current_win()

    if type(on_click.callback) == "string" then
        return on_click.callback
    end

    local func_name = type(on_click.name) == "function" and on_click.name(component) or on_click.name
    if _G[func_name] and not on_click.update then
        return "v:lua." .. func_name
    end

    _G[func_name] = function(minwid, nclicks, button)
        on_click.callback(component, winid, minwid, nclicks, button)
    end
    return "v:lua." .. func_name
end

---@param component StatusLine
local function register_update_autocmd(component)
    local events, callback
    if type(component.update) == "string" then
        events = component.update
    else
        events = {}
        for i, e in ipairs(component.update) do
            table.insert(events, e)
        end
        callback = component.update.callback
    end

    local id = vim.api.nvim_create_autocmd(events, {
        callback = function()
            component._win_stl = nil
            if callback then
                callback(component)
            end
        end,
        desc = "Heirline update autocmd for " .. vim.inspect(component.id),
        group = "Heirline_update_autocmds",
    })
    component._au_id = id
end

---Evaluate component and its children recursively
---@return string
function StatusLine:eval()
    if self.condition and not self:condition() then
        -- self.stl = ''
        return ""
    end

    if self.update then
        if type(self.update) == "function" then
            if self:update() then
                self._win_stl = nil
            end
        else
            if not self._au_id then
                register_update_autocmd(self)
            end
        end

        local win_stl = self:get_win_attr("_win_stl")
        if win_stl then
            return win_stl
        end
    end

    if self.init then
        self:init()
    end

    local stl = {}

    local hl = type(self.hl) == "function" and (self:hl() or {}) or self.hl -- self raw hl

    if type(hl) == "string" then
        hl = utils.get_highlight(hl)
    end

    local parent_hl = self:nonlocal("merged_hl")

    if parent_hl.force then
        self.merged_hl = vim.tbl_extend("keep", parent_hl, hl)
    else
        self.merged_hl = vim.tbl_extend("force", parent_hl, hl)
    end

    if self.on_click then
        local func_name = register_global_function(self)
        table.insert(stl, "%@" .. func_name .. "@")
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

    if self.on_click then
        table.insert(stl, "%X")
    end

    self.stl = table.concat(stl, "")

    if self.after then
        self:after()
    end

    if self.update then
        self:set_win_attr("_win_stl", self.stl)
    end

    return self.stl
end

return StatusLine
