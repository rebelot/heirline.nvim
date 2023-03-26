local M = {}
local nvim_eval_statusline = vim.api.nvim_eval_statusline
local nvim_buf_get_option = vim.api.nvim_buf_get_option
local nvim_list_bufs = vim.api.nvim_list_bufs
local nvim_buf_is_valid = vim.api.nvim_buf_is_valid
local tbl_contains = vim.tbl_contains
local tbl_keys = vim.tbl_keys
local tbl_filter = vim.tbl_filter

local function get_highlight_deprecated(name)
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

local function get_highlight(name)
    return vim.api.nvim_get_hl(0, { name = name, link = false })
end

---Get highlight properties for a given highlight name
---@type fun(name: string): table
M.get_highlight = vim.fn.exists("*nvim_get_hl") == 1 and get_highlight or get_highlight_deprecated


---Copy the given component, merging its fields with `with`
---@param block table
---@param with? table
---@return table
function M.clone(block, with)
    return vim.tbl_deep_extend("force", block, with or {})
end

---Surround component with separators and adjust coloring
---@param delimiters string[]
---@param color string|function|nil
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
    return nvim_eval_statusline(str, { winid = 0, maxwidth = 0 }).width
end

local function with_cache(func, cache, au_id)
    cache = cache or {}
    if not au_id then
        au_id = vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
            callback = function()
                for i = 1, #cache do
                    cache[i] = nil
                end
            end,
            desc = "Heirline: release cache for buflist get_bufs()",
        })
        return with_cache(func, cache, au_id)
    end
    return function()
        if next(cache) then
            return cache
        else
            local res = func()
            for i, v in ipairs(res) do
                cache[i] = v
            end
            for i = #res + 1, #cache do
                cache[i] = nil
            end
            return res
        end
    end
end

local function get_bufs()
    return tbl_filter(function(bufnr)
        return nvim_buf_get_option(bufnr, "buflisted")
    end, nvim_list_bufs())
end

local function bufs_in_tab(tabpage)
    tabpage = tabpage or 0
    local buf_set = {}
    local wins = vim.api.nvim_tabpage_list_wins(tabpage)
    for _, winid in ipairs(wins) do
        local bufnr = vim.api.nvim_win_get_buf(winid)
        buf_set[bufnr] = true
    end
    return buf_set
end

--- Make a tablist, rendering all open tabs
--- using `tab_component` as a template.
---@param tab_component table
---@return table
function M.make_tablist(tab_component)
    local tablist = {
        init = function(self)
            local tabpages = vim.api.nvim_list_tabpages()
            for i, tabpage in ipairs(tabpages) do
                local tabnr = vim.api.nvim_tabpage_get_number(tabpage)
                local child = self[i]
                if not (child and child.tabpage == tabpage) then
                    self[i] = self:new(tab_component, i)
                    child = self[i]
                    child.tabnr = tabnr
                    child.tabpage = tabpage
                end
                if tabpage == vim.api.nvim_get_current_tabpage() then
                    child.is_active = true
                    self.active_child = i
                else
                    child.is_active = false
                end
            end
            if #self > #tabpages then
                for i = #self, #tabpages + 1, -1 do
                    self[i] = nil
                end
            end
        end,
    }
    return tablist
end

-- record how many times users called this function
-- TODO: might be worth it to export the callback and delegate the user to create the next/prev components on_click fields, removing all defaults
local NTABLINES = 0

--- Make a list of buffers, rendering all listed buffers
--- using `buffer_component` as a template.
---@param buffer_component table
---@param left_trunc? table left truncation marker, shown is buffer list is too long
---@param right_trunc? table right truncation marker, shown is buffer list is too long
---@param buf_func? function return a list of <integer> bufnr handlers.
---@param buf_cache? table|boolean reference to the buflist cache or false to disable caching
---@return table
function M.make_buflist(buffer_component, left_trunc, right_trunc, buf_func, buf_cache)
    buf_func = buf_func or get_bufs
    if buf_cache ~= false then
        buf_func = with_cache(buf_func, buf_cache)
    end

    left_trunc = left_trunc or {
        provider = "<",
    }

    right_trunc = right_trunc or {
        provider = ">",
    }

    NTABLINES = NTABLINES + 1
    left_trunc.on_click = {
        callback = function(self)
            self._buflist[1]._cur_page = self._cur_page - 1
            self._buflist[1]._force_page = true
            vim.cmd("redrawtabline")
        end,
        name = "Heirline_tabline_prev_" .. NTABLINES,
    }

    right_trunc.on_click = {
        callback = function(self)
            self._buflist[1]._cur_page = self._cur_page + 1
            self._buflist[1]._force_page = true
            vim.cmd("redrawtabline")
        end,
        name = "Heirline_tabline_next_" .. NTABLINES,
    }

    local bufferline = {
        static = {
            _left_trunc = left_trunc,
            _right_trunc = right_trunc,
            _cur_page = 1,
            _force_page = false,
        },
        init = function(self)
            -- register the buflist component reference as global statusline attr
            if vim.tbl_isempty(self._buflist) then
                table.insert(self._buflist, self)
            end
            if not self.left_trunc then
                self.left_trunc = self:new(self._left_trunc)
            end
            if not self.right_trunc then
                self.right_trunc = self:new(self._right_trunc)
            end

            if not self._once then
                vim.api.nvim_create_autocmd({ "BufEnter" }, {
                    callback = function()
                        self._force_page = false
                    end,
                    desc = "Heirline release lock for next/prev buttons",
                })
                self._once = true
            end

            self.active_child = false
            local bufs = tbl_filter(function(bufnr)
                return nvim_buf_is_valid(bufnr)
            end, buf_func())
            local visible_buffers = bufs_in_tab()

            for i, bufnr in ipairs(bufs) do
                local child = self[i]
                if not (child and child.bufnr == bufnr) then
                    self[i] = self:new(buffer_component, i)
                    child = self[i]
                    child.bufnr = bufnr
                end

                if bufnr == tonumber(vim.g.actual_curbuf) then
                    child.is_active = true
                    self.active_child = i
                else
                    child.is_active = false
                end

                if visible_buffers[bufnr] then
                    child.is_visible = true
                else
                    child.is_visible = false
                end
            end
            if #self > #bufs then
                for i = #bufs + 1, #self do
                    self[i] = nil
                end
            end
        end,
    }
    return bufferline
end

--- Private function
---@param buflist table
function M.page_buflist(buflist, maxwidth)
    if not buflist or #buflist == 0 then
        return
    end

    local bfl = {}
    maxwidth = maxwidth - 2 -- leave some space for {right,left}_trunc

    local pages = { {} }
    local active_page
    local page_counter = 1
    local page_length = 0
    local active_page_index

    local page = pages[1]
    for _, child in ipairs(buflist) do
        local len = M.count_chars(child:traverse())

        if page_length + len > maxwidth then
            page_length = 0
            page = {}
            table.insert(pages, page)
            page_counter = page_counter + 1
        end

        table.insert(page, child)
        page_length = page_length + len

        if child.is_active then
            active_page = page
            active_page_index = page_counter
        end
    end

    local page_index
    if active_page and not buflist._force_page then
        page = active_page
        page_index = active_page_index
        buflist._cur_page = page_index
    else
        page = pages[buflist._cur_page]
        page_index = buflist._cur_page
    end

    if not page then
        -- print("Invalid page nr.", page_index, 'for', #pages, 'pages')
        return
    end

    if page_index > 1 then
        table.insert(bfl, buflist.left_trunc:eval())
    end

    for _, child in ipairs(page) do
        table.insert(bfl, child:traverse())
    end

    -- table.insert(tbl, "%=")

    if page_index < #pages then
        table.insert(bfl, buflist.right_trunc:eval())
    end
    buflist:clear_tree()
    buflist._tree[1] = table.concat(bfl, "")
end

---ColorScheme callback useful to reset highlights
---@param colors table|function
function M.on_colorscheme(colors)
    colors = colors or {}
    local hl = require("heirline")
    hl.reset_highlights()
    hl.clear_colors()
    hl.load_colors(colors)
    local reset_win_cache = function(self)
        self._win_cache = nil
    end
    if hl.statusline then
        hl.statusline:broadcast(reset_win_cache)
    end
    if hl.winbar then
        hl.winbar:broadcast(reset_win_cache)
    end
    if hl.tabline then
        hl.tabline:broadcast(reset_win_cache)
    end
end

return M
