local utils = require("heirline.utils")
local hi = require("heirline.highlights")

local default_restrict = {
    init = true,
    provider = true,
    condition = true,
    restrict = true,
    pick_child = true,
    after = true,
    on_click = true,
    update = true,
    _win_cache = true,
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
---@field id table<integer>
---@field winnr integer
---@field _win_cache? table
---@field _au_id? integer
---@field _tree table
---@field _updatable_components table
---@field _flexible_components table
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
    new.pick_child = child.pick_child and vim.tbl_extend("keep", child.pick_child, {})
    new.init = child.init
    new.provider = child.provider
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
    return rawget(self, attr)
end

local function cleanup_win_attr(win_attr)
    if not win_attr then
        return
    end
    local nwin = #vim.api.nvim_tabpage_list_wins(0)
    if #win_attr > nwin then
        for i = nwin + 1, #win_attr do
            win_attr[i] = nil
        end
    end
end

--- Set window-nr attribute
---@param attr string
---@param val any
---@param default any
function StatusLine:set_win_attr(attr, val, default)
    cleanup_win_attr(self[attr])
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
    if not self[attr] then
        if default then
            self[attr] = {}
        else
            return
        end
    end
    self[attr][winnr] = self[attr][winnr] or default
    return self[attr][winnr]
end

---@param component StatusLine
---@return string
local function register_global_function(component)
    local on_click = component.on_click

    if type(on_click.callback) == "string" then
        return on_click.callback
    end

    local func_name = type(on_click.name) == "function" and on_click.name(component) or on_click.name
    if _G[func_name] and not on_click.update then
        return "v:lua." .. func_name
    end

    _G[func_name] = function(minwid, nclicks, button)
        on_click.callback(component, minwid, nclicks, button)
    end
    return "v:lua." .. func_name
end

---@param component StatusLine
local function register_update_autocmd(component)
    local events, callback, pattern
    if type(component.update) == "string" then
        events = component.update
    else
        events = {}
        for i, e in ipairs(component.update) do
            table.insert(events, e)
        end
        callback = component.update.callback
        pattern = component.update.pattern
    end

    local id = vim.api.nvim_create_autocmd(events, {
        pattern = pattern,
        callback = function(args)
            component._win_cache = nil
            if callback then
                callback(component, args)
            end
        end,
        desc = "Heirline update autocmd for " .. vim.inspect(component.id),
        group = "Heirline_update_autocmds",
    })
    component._au_id = id
end

---Evaluate component and its children recursively
---@return nil
function StatusLine:_eval()
    if not self:local_("_tree") then
        -- root component has no parent tree
        -- may be "stray" component
        self._tree = {}
    else
        -- clear the tree at each cycle
        self:clear_tree()
    end

    if self.condition and not self:condition() then
        return
    end

    if self.update then
        if type(self.update) == "function" then
            if self:update() then
                self._win_cahe = nil
            end
        else
            if not self._au_id then
                register_update_autocmd(self)
            end
        end

        local win_cache = self:get_win_attr("_win_cache")
        if win_cache then
            self._tree[1] = win_cache
            return
        end
    end

    if self.init then
        self:init()
    end

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
        local minwid = type(self.on_click.minwid) == "function" and self.on_click.minwid(self)
            or self.on_click.minwid
            or ""
        table.insert(self._tree, "%" .. minwid .. "@" .. func_name .. "@")
    end

    if self.provider then
        local provider_str = type(self.provider) == "function" and (self:provider() or "") or (self.provider or "")
        local hl_str_start, hl_str_end = hi.eval_hl(self.merged_hl)
        table.insert(self._tree, hl_str_start .. provider_str .. hl_str_end)
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
        child._tree = {}
        table.insert(self._tree, child._tree)
        child:_eval()
    end

    if self.on_click then
        table.insert(self._tree, "%X")
    end

    if self.after then
        self:after()
    end

    if self.update then
        self:set_win_attr("_win_cache", self._tree)
        table.insert(self._updatable_components, self)
    end
end

function StatusLine:traverse(tree, stl)
    stl = stl or {}
    tree = tree or self._tree

    if not tree then
        return ""
    end

    for _, node in ipairs(tree) do
        if type(node) ~= "table" then
            table.insert(stl, node)
        else
            self:traverse(node, stl)
        end
    end
    return table.concat(stl, "")
end

function StatusLine:clear_tree()
    local tree = rawget(self, "_tree")
    if not tree then
        return
    end
    for i, _ in ipairs(tree) do
        self._tree[i] = nil
    end
end

-- this MUST be called at the end of the main loop
function StatusLine:_freeze_cache()
    for _, component in ipairs(self._updatable_components) do
        local win_cache = component:get_win_attr("_win_cache") -- check nil?
        local fixed_cache = component:traverse(win_cache)
        component:set_win_attr("_win_cache", fixed_cache)
        component:clear_tree()
        component._tree[1] = fixed_cache
    end
end

function StatusLine:eval()
    self:_eval()
    return self:traverse()
end

return StatusLine
