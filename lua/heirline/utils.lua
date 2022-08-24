local M = {}

---Get highlight properties for a given highlight name
---@param name string
---@return table
function M.get_highlight(name)
    local hl = vim.api.nvim_get_hl_by_name(name, vim.o.termguicolors)
    if vim.o.termguicolors then
        hl.fg = hl.foreground
        hl.bg = hl.background
        hl.sp = hl.special
        hl.foreground = nil
        hl.background = nil
        hl.special = nil
    else
        hl.ctermfg = hl.foreground
        hl.ctermbg = hl.background
        hl.foreground = nil
        hl.background = nil
        hl.special = nil
    end
    return hl
end

---Copy the given component
---@param block table
---@param with? table
---@return table
function M.clone(block, with)
    return vim.tbl_deep_extend("force", block, with or {})
end

---Surround component with separators and adjust coloring
---@param delimiters table<string>
---@param color string | function
---@param component table
---@return table
function M.surround(delimiters, color, component)
    component = M.clone(component)

    local surround_color = function(self)
        if type(color) == "function" then
            return color(self)
        else
            return color
        end
    end

    return {
        {
            provider = delimiters[1],
            hl = function(self)
                local s_color = surround_color(self)
                if s_color then
                    return { fg = s_color }
                end
            end,
        },
        {
            hl = function(self)
                local s_color = surround_color(self)
                if s_color then
                    return { bg = s_color }
                end
            end,
            component,
        },
        {
            provider = delimiters[2],
            hl = function(self)
                local s_color = surround_color(self)
                if s_color then
                    return { fg = s_color }
                end
            end,
        },
    }
end

---return a copy of `destination` component where each `child` in `...`
---(variable arguments) is appended to its children (if any).
---@param destination table
---@vararg table
---@return table
function M.insert(destination, ...)
    local children = { ... }
    local new = M.clone(destination)
    for _, child in ipairs(children) do
        local new_child = M.clone(child)
        table.insert(new, new_child)
    end
    return new
end

---Calculate the length of a format-string
---@param str string
---@return integer
function M.count_chars(str)
    return vim.api.nvim_eval_statusline(str, { winid = 0, maxwidth = 0 }).width
end

---Create a flexible component
---@param priority integer
---@vararg table
---@return table
function M.make_flexible_component(priority, ...)
    local new = M.insert({}, ...)

    new.static = {
        _priority = priority,
    }
    new.init = function(self)
        if not vim.tbl_contains(self.flexible_components, self) then
            table.insert(self.flexible_components, self)
        end
        self:set_win_attr("_win_child_index", nil, 1)
        self.pick_child = { self:get_win_attr("_win_child_index") }
    end
    new.restrict = { _win_child_index = true }

    return new
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

local function is_child(child, parent)
    if not (child and parent) then
        return false
    end
    if #child.id <= #parent.id then
        return false
    end
    for i, v in ipairs(parent.id) do
        if child.id[i] ~= v then
            return false
        end
    end
    return true
end

local function group_flexible_components(statusline, mode)
    local priority_groups = {}
    local priorities = {}
    local cur_priority
    local prev_component

    for _, component in ipairs(statusline.flexible_components) do
        local priority
        if prev_component and is_child(component, prev_component) then
            priority = cur_priority + mode
            -- if mode == -1 then
            --     priority = ec.priority < cur_priority + mode and ec.priority or cur_priority + mode
            -- elseif mode == 1 then
            --     priority = ec.priority > cur_priority + mode and ec.priority or cur_priority + mode
            -- end
        else
            priority = component._priority
        end

        prev_component = component
        cur_priority = priority

        priority_groups[priority] = priority_groups[priority] or {}
        table.insert(priority_groups[priority], component)
        if not priorities[priority] then
            table.insert(priorities, priority)
        end
    end
    return priority_groups, priorities
end

function M.expand_or_contract_flexible_components(statusline, full_width, out)
    if not statusline.flexible_components or not next(statusline.flexible_components) then
        return
    end

    local winw
    if full_width then
        winw = vim.o.columns
    else
        winw = vim.api.nvim_win_get_width(0)
    end

    local stl_len = M.count_chars(out)

    if stl_len > winw then
        local priority_groups, priorities = group_flexible_components(statusline, -1)
        table.sort(priorities, function(a, b)
            return a < b
        end)

        local saved_chars = 0

        for _, p in ipairs(priorities) do
            for _, component in ipairs(priority_groups[p]) do
                -- try increasing the child index and return success
                if next_child(component) then
                    local prev_len = M.count_chars(component.stl)
                    local cur_len = M.count_chars(component:eval())
                    saved_chars = saved_chars + (prev_len - cur_len)
                end
            end

            if stl_len - saved_chars <= winw then
                break
            end
        end
    elseif stl_len < winw then
        local gained_chars = 0

        local priority_groups, priorities = group_flexible_components(statusline, 1)
        table.sort(priorities, function(a, b)
            return a > b
        end)

        for _, p in ipairs(priorities) do
            for _, component in ipairs(priority_groups[p]) do
                if prev_child(component) then
                    local prev_len = M.count_chars(component.stl)
                    local cur_len = M.count_chars(component:eval())
                    gained_chars = gained_chars + (cur_len - prev_len)
                end
            end

            if stl_len + gained_chars > winw then
                for _, component in ipairs(priority_groups[p]) do
                    next_child(component)
                end
                break
            end
        end
    end
end

function M.pick_child_on_condition(self)
    self.pick_child = {}
    for i, child in ipairs(self) do
        if not child.condition or child:condition() then
            table.insert(self.pick_child, i)
            break
        end
    end
end

local function get_bufs()
    return vim.tbl_filter(function(bufnr)
        return vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buflisted
    end, vim.api.nvim_list_bufs())
end

function M.make_buflist(buffer_component, right_trunc, left_trunc)
    right_trunc = right_trunc
        or require("heirline.statusline"):new({
            provider = "%=>",
            hl = { fg = "gray" },
        })

    left_trunc = left_trunc
        or require("heirline.statusline"):new({
            provider = "<",
            hl = { fg = "gray" },
        })

    local bufferline = {
        static = {
            left_trunc = left_trunc,
            right_trunc = right_trunc,
        },
        init = function(self)
            if vim.tbl_isempty(self._buflist) then
                table.insert(self._buflist, self)
            end

            local bufs = get_bufs()
            for i, bufnr in ipairs(bufs) do
                if not (self[i] and bufnr == self[i].bufnr) then
                    self[i] = require("heirline.statusline"):new(buffer_component, i)
                    self[i].bufnr = bufnr
                end
                if bufnr == tonumber(vim.g.actual_curbuf) then
                    self[i].is_active = true
                    self.active_child = i
                else
                    self[i].is_active = false
                end
            end
            if #self > #bufs then
                for i = #self, #bufs + 1, -1 do
                    self[i] = nil
                end
            end
        end,
        after = function(self)
            if not self._eval_buflist then
                self.stl = "#BUFLIST#"
                return
            end
            self.stl = ""
            -- local maxwidth = vim.o.columns
            local maxwidth = self._maxwidth - 2

            local page = {}
            local active_page
            local page_length = 0
            local page_start = 1
            local page_end = #self
            for i, child in ipairs(self) do
                local len = M.count_chars(child.stl)
                page_length = page_length + len
                if page_length <= maxwidth then
                    table.insert(page, child)
                else
                    if not active_page then
                        page_length = len
                        page = { child }
                        page_start = i
                    else
                        page_end = i
                        break
                    end
                end
                if child.is_active then
                    active_page = page
                end
            end
            if page_start > 1 then
                self.stl = self.left_trunc:eval()
            end
            for _, child in ipairs(page) do
                self.stl = self.stl .. child.stl
            end
            if page_end < #self then
                self.stl = self.stl .. self.right_trunc:eval()
            end
        end,
    }
    return bufferline
end

function M.page_buflist(self)
    self.stl = ""
    -- local maxwidth = vim.o.columns
    local maxwidth = self._maxwidth - 2

    local page = {}
    local active_page
    local page_length = 0
    local page_start = 1
    local page_end = #self
    for i, child in ipairs(self) do
        local len = M.count_chars(child.stl)
        page_length = page_length + len
        if page_length <= maxwidth then
            table.insert(page, child)
        else
            if not active_page then
                page_length = len
                page = { child }
                page_start = i
            else
                page_end = i
                break
            end
        end
        if child.is_active then
            active_page = page
        end
    end
    if page_start > 1 then
        self.stl = self.left_trunc:eval()
    end
    for _, child in ipairs(page) do
        self.stl = self.stl .. child.stl
    end
    if page_end < #self then
        self.stl = self.stl .. self.right_trunc:eval()
    end
end

return M
