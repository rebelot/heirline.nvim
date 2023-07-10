local utils = require("heirline.utils")
local count_chars = utils.count_chars
local hi = require("heirline.highlights")
local eval_hl = hi.eval_hl
local tbl_insert = table.insert
local tbl_concat = table.concat
local tbl_keys = vim.tbl_keys
local tbl_extend = vim.tbl_extend
local tbl_deep_extend = vim.tbl_deep_extend
local tbl_contains = vim.tbl_contains
local str_format = string.format

local default_restrict = {
    init = true,
    provider = true,
    hl = true,
    condition = true,
    restrict = true,
    pick_child = true,
    after = true,
    on_click = true,
    update = true,
    fallthrough = true,
    _win_cache = true,
    _au_id = true,
    _win_child_index = true,
}

---@alias HeirlineColor string|integer Type: string to hex color code, color alias defined by heirline.load_colors() or fallback to vim standard color name; integer to 24-bit color.
---@alias HeirlineCtermColor string|integer Type: integer to 8-bit color, string to color name alias or default color name.
---@alias HeirlineCtermStyle ("bold"|"underline"|"undercurl"|"underdouble"|"underdotted"|"underdashed"|"strikethrough"|"reverse"|"inverse"|"italic"|"standout"|"altfont"|"nocombine")[]|"NONE"

---@class HeirlineHighlight
---@field fg? HeirlineColor  The foreground color
---@field bg? HeirlineColor  The background color
---@field sp? HeirlineColor  The underline/undercurl color, if any
---@field bold? boolean
---@field italic? boolean
---@field reverse? boolean
---@field inverse? boolean
---@field standout? boolean
---@field underline? boolean
---@field undercurl? boolean
---@field underdouble? boolean
---@field underdotted? boolean
---@field underdashed? boolean
---@field strikethrough? boolean
---@field altfont? boolean
---@field nocombine? boolean
---@field ctermfg? HeirlineCtermColor  The foreground color
---@field ctermbg? HeirlineCtermColor  The background color
---@field cterm? HeirlineCtermStyle  The special style for cterm
---@field force? boolean  Control whether the parent's hl fields will override child's hl

---@alias HeirlineOnClickCallback fun(self: StatusLine, minwid: integer, nclicks: integer, button: "l"|"m"|"r", mods: string)
---@class HeirlineOnClick
---@field callback? string|HeirlineOnClickCallback
---@field name? string|fun():string
---@field update? boolean
---@field minwid? number|fun():integer

---@class StatusLine
---@field condition? fun(self: StatusLine): any
---@field init? fun(self: StatusLine): any
---@field provider? string|number|fun(self: StatusLine):string|number|nil
---@field hl? HeirlineHighlight|string|fun(self: StatusLine): HeirlineHighlight|string|nil  controls the colors of what is printed by the component's provider, or by any of its descendants.
---@field restrict? table<string, boolean>
---@field after? fun(self: StatusLine): any
---@field update? table|string|fun(self: StatusLine): boolean
---@field on_click? HeirlineOnClickCallback|HeirlineOnClick
---@field id integer[]
---@field winnr integer
---@field fallthrough boolean
---@field flexible integer
---@field _win_cache? table
---@field _au_id? integer
---@field _tree table
---@field _updatable_components table
---@field _flexible_components table
---@field pick_child? integer[]
local StatusLine = {}

---Initialize a new statusline object
---@param child table
---@param index? integer
---@return StatusLine
function StatusLine:new(child, index)
    child = child or {}
    local new = {}

    if child.hl then
        local hl_type = type(child.hl)
        if hl_type == "function" or hl_type == "string" then
            new.hl = child.hl
        elseif hl_type == "table" then
            new.hl = tbl_extend("keep", child.hl, {})
        end
    end

    if child.update then
        local update_type = type(child.update)
        if tbl_contains({ "function", "string" }, update_type) then
            new.update = child.update
        elseif update_type == "table" then
            new.update = tbl_extend("keep", child.update, {})
        end
    end

    new.condition = child.condition
    new.pick_child = child.pick_child and tbl_extend("keep", child.pick_child, {})
    if child.fallthrough ~= nil then
        new.fallthrough = child.fallthrough
    else
        new.fallthrough = true
    end
    new.init = child.init
    new.provider = child.provider
    new.after = child.after
    new.flexible = child.flexible
    new.on_click = child.on_click and tbl_extend("keep", child.on_click, {})
    new.restrict = child.restrict and tbl_extend("keep", child.restrict, {})

    if child.static then
        for k, v in pairs(tbl_deep_extend("keep", child.static, {})) do
            new[k] = v
        end
    end

    local restrict = tbl_extend("force", default_restrict, self.restrict or {})
    setmetatable(new, self)
    self.__index = function(t, v)
        if not restrict[v] then
            return self[v]
        end
    end

    local parent_id = self.id or {}
    new.id = tbl_extend("force", parent_id, { [#parent_id + 1] = index })

    for i, sub in ipairs(child) do
        new[i] = new:new(sub, i)
    end

    return new
end

--- Broadcast a function that will be executed by every component
---@param func function
function StatusLine:broadcast(func)
    func(self)
    for i, c in ipairs(self) do
        c:broadcast(func)
    end
end

--- Get the component where func(component) evaluates to true
---@param func function predicate
---@return StatusLine|nil
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

function StatusLine:is_child(other)
    if not other then
        return false
    end
    if #self.id <= #other.id then
        return false
    end
    for i, v in ipairs(other.id) do
        if self.id[i] ~= v then
            return false
        end
    end
    return true
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
    if not on_click then
        error()
    end

    if type(on_click.callback) == "string" then
        return on_click.callback
    end

    local func_name = type(on_click.name) == "function" and on_click.name(component) or on_click.name
    if _G[func_name] and not on_click.update then
        return "v:lua." .. func_name
    end

    _G[func_name] = function(...)
        on_click.callback(component, ...)
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
            tbl_insert(events, e)
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
---@return boolean
function StatusLine:_eval()
    if not self:local_("_tree") then
        -- root component has no parent tree
        -- may be "stray" component
        self._tree = {}
    else
        -- clear the tree at each cycle
        self:clear_tree()
    end

    local tree = self._tree

    if self.condition and not self:condition() then
        return false
    end

    local update = self.update
    if update then
        if type(update) == "function" then
            if update(self) then
                self._win_cache = nil
            end
        else
            if not self._au_id then
                register_update_autocmd(self)
            end
        end

        local win_cache = self:get_win_attr("_win_cache")
        if win_cache then
            tree[1] = win_cache
            return true
        end
    end

    if self.init then
        self:init()
    end

    if rawget(self, "flexible") then
        if not tbl_contains(self._flexible_components, self) then
            table.insert(self._flexible_components, self)
        end
        self:set_win_attr("_win_child_index", nil, 1)
        self.pick_child = { self:get_win_attr("_win_child_index") }
        -- alwaus prefer parent priority
        self._priority = self._priority or self.flexible
    end

    local hl = self.hl or {}
    hl = type(hl) == "function" and (hl(self) or {}) or hl -- self raw hl, <string,table,nil>

    if type(hl) == "string" then
        hl = utils.get_highlight(hl)
    end

    local parent_hl = self:nonlocal("merged_hl")

    if not parent_hl then
        self.merged_hl = hl
    elseif parent_hl.force then
        self.merged_hl = tbl_extend("keep", parent_hl, hl)
    else
        self.merged_hl = tbl_extend("force", parent_hl, hl)
    end

    local on_click = self.on_click
    if on_click then
        local func_name = register_global_function(self)
        local minwid = on_click.minwid or ""
        minwid = type(minwid) == "function" and minwid(self) or minwid
        tbl_insert(tree, str_format("%%%s@%s@", minwid, func_name))
    end

    local provider = self.provider
    if provider then
        local provider_str = type(provider) == "function" and (provider(self) or "") or (provider or "")
        local hl_str_start, hl_str_end = eval_hl(self.merged_hl)
        tbl_insert(tree, hl_str_start .. provider_str .. hl_str_end)
    end

    local pick_child = self.pick_child
    local picked_children
    if pick_child then
        picked_children = {}
        for _, i in ipairs(pick_child) do
            tbl_insert(picked_children, self[i])
        end
    end

    for _, child in ipairs(picked_children or self) do
        child._tree = {}
        tbl_insert(tree, child._tree)
        local ret = child:_eval()
        if not ret then
            table.remove(tree)
        end
        if ret and not self.fallthrough then
            break
        end
    end

    if on_click then
        tbl_insert(tree, "%X")
    end

    if self.after then
        self:after()
    end

    if update then
        tbl_insert(self._updatable_components, self)
    end
    return true
end

---private
---Traverse a nested tree and return the flattened tree
---@param tree table
---@param flat_tree? table
---@return table
local function traverse(tree, flat_tree)
    flat_tree = flat_tree or {}

    if not tree then
        return {}
    end

    for _, node in ipairs(tree) do
        if type(node) ~= "table" then
            tbl_insert(flat_tree, node)
        else
            traverse(node, flat_tree)
        end
    end
    return flat_tree
end

--- Traverse the component nested tree and return the statusline string
---@return string statusline the statusline string
function StatusLine:traverse()
    local tree = rawget(self, "_tree")
    local flat_tree = traverse(tree)
    return tbl_concat(flat_tree, "")
end

--- Empty the component tree leaving its reference intact
function StatusLine:clear_tree()
    local tree = rawget(self, "_tree")
    if not tree then
        return
    end
    for i = 1, #tree do
        tree[i] = nil
    end
end

-- this MUST be called at the end of the main loop
function StatusLine:_freeze_cache()
    for _, component in ipairs(self._updatable_components) do
        local fixed_cache = component:traverse()
        component:set_win_attr("_win_cache", fixed_cache)
        component:clear_tree()
        component._tree[1] = fixed_cache
    end
end

function StatusLine:eval()
    self:_eval()
    return self:traverse()
end

function StatusLine:is_empty()
    return self:traverse() == ""
end

local function next_child(self)
    local pi = self:get_win_attr("_win_child_index") + 1
    if pi > #self then
        return false
    end
    self:set_win_attr("_win_child_index", pi)
    return true
end

local function prev_child(self)
    local pi = self:get_win_attr("_win_child_index") - 1
    if pi < 1 then
        return false
    end
    self:set_win_attr("_win_child_index", pi)
    return true
end

local function group_flexible_components(flexible_components, mode)
    local priority_groups = {}
    local cur_priority
    local prev_component
    local prev_parent

    for _, component in ipairs(flexible_components) do
        local priority
        if prev_component and component:is_child(prev_component) then
            prev_parent = prev_component
            priority = cur_priority + mode
            -- if mode == -1 then
            --     priority = ec.priority < cur_priority + mode and ec.priority or cur_priority + mode
            -- elseif mode == 1 then
            --     priority = ec.priority > cur_priority + mode and ec.priority or cur_priority + mode
            -- end
        elseif prev_parent and component:is_child(prev_parent) then
            priority = cur_priority
        else
            priority = component._priority
        end

        prev_component = component
        cur_priority = priority

        priority_groups[priority] = priority_groups[priority] or {}
        table.insert(priority_groups[priority], component)
    end

    local priorities = tbl_keys(priority_groups)
    local comp = mode == -1 and function(a, b)
        return a < b
    end or function(a, b)
        return a > b
    end
    table.sort(priorities, comp)
    return priority_groups, priorities
end

---@param full_width boolean
---@param out string
function StatusLine:expand_or_contract_flexible_components(full_width, out)
    local flexible_components = self._flexible_components
    if not flexible_components or not next(flexible_components) then
        return
    end

    local winw = (full_width and vim.o.columns) or vim.api.nvim_win_get_width(0)

    local stl_len = count_chars(out)

    if stl_len > winw then
        local priority_groups, priorities = group_flexible_components(flexible_components, -1)

        local saved_chars = 0

        for _, p in ipairs(priorities) do
            while true do
                local out_of_components = true
                for _, component in ipairs(priority_groups[p]) do
                    -- try increasing the child index and return success
                    if next_child(component) then
                        out_of_components = false
                        local prev_len = count_chars(component:traverse())
                        local cur_len = count_chars(component:eval())
                        -- component:clear_tree()
                        -- component._tree[1] = component[component:get_win_attr("_win_child_index")]:traverse()
                        saved_chars = saved_chars + (prev_len - cur_len)
                    end
                end

                if stl_len - saved_chars <= winw then
                    return
                end

                if out_of_components then
                    break
                end
            end
        end
    elseif stl_len < winw then
        local gained_chars = 0

        local priority_groups, priorities = group_flexible_components(flexible_components, 1)

        for _, p in ipairs(priorities) do
            while true do
                local out_of_components = true
                for _, component in ipairs(priority_groups[p]) do
                    if prev_child(component) then
                        out_of_components = false
                        local prev_len = count_chars(component:traverse())
                        local cur_len = count_chars(component:eval())
                        -- component:clear_tree()
                        gained_chars = gained_chars + (cur_len - prev_len)
                    end
                end

                if stl_len + gained_chars > winw then
                    for _, component in ipairs(priority_groups[p]) do
                        next_child(component)
                        -- here we need to manually reset the component tree, as we are increasing the
                        -- child index but without calling eval (wich should handle that);
                        -- since we went "one index too little", the next-index child tree has been already evaluated
                        -- in the previous loop.
                        component:clear_tree()
                        component._tree[1] = component[component:get_win_attr("_win_child_index")]:traverse()
                    end
                    return
                end
                if out_of_components then
                    break
                end
            end
        end
    end
end
return StatusLine
