local M = {}

function M.get_highlight(hlname)
    local hl = vim.api.nvim_get_hl_by_name(hlname, true)
    local t = {}
    local hex = function(n)
        if n then
            return string.format("#%06x", n)
        end
    end
    t.fg = hex(hl.foreground)
    t.bg = hex(hl.background)
    t.sp = hex(hl.special)
    t.style = "none,"
    if hl.underline then
        t.style = t.style .. "underline"
    end
    if hl.undercurl then
        t.style = t.style .. "undercurl"
    end
    if hl.bold then
        t.style = t.style .. "bold"
    end
    if hl.italic then
        t.style = t.style .. "italic"
    end
    if hl.reverse then
        t.style = t.style .. "reverse"
    end
    if hl.nocombine then
        t.style = t.style .. "nocombine"
    end
    return t
end

function M.clone(block, with)
    return vim.tbl_deep_extend("force", block, with or {})
end

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

function M.insert(destination, ...)
    local children = { ... }
    local new = M.clone(destination)
    for _, child in ipairs(children) do
        local new_child = M.clone(child)
        table.insert(new, new_child)
    end
    return new
end

function M.count_chars(str)
    return vim.api.nvim_eval_statusline(str, { winid = 0, maxwidth = 0 }).width
end

local function next_p(self)
    local pi = self:get_win_attr("pi") + 1
    if pi > #self then
        pi = #self
    end
    self:set_win_attr("pi", pi)
end

function M.make_elastic_component(priority, ...)
    local new = {}
    local components = { ... }
    for i, c in ipairs(components) do
        new[i] = vim.tbl_deep_extend("keep", c, {})
    end
    new.static = {
        priority = priority,
        next_p = next_p
    }
    new.init = function(self)
        if self.pre_eval then
            self.elastic_ids[self.priority] = self.elastic_ids[self.priority] or {}
            table.insert(self.elastic_ids[self.priority], self.id)
            self:set_win_attr("pi", 1)
        end
        self.pick_child = {self:get_win_attr("pi")}
    end

    return new
end

function M.elastic_before(statusline, last_out)
    local winw = vim.api.nvim_win_get_width(0)

    statusline.elastic_ids = {}
    statusline.pre_eval = true

    local stl_max_len = M.count_chars(statusline:eval())

    statusline.pre_eval = false

    if stl_max_len > winw then
        local saved_chars = 0
        local get_out = false
        for _, ids in pairs(statusline.elastic_ids) do
            local max_count = 0
            for _, id in ipairs(ids) do
                local ec = statusline:get(id)
                max_count = max_count + #ec
            end

            local i = 0
            while i <= max_count do
                for _, id in ipairs(ids) do
                    local ec = statusline:get(id)
                    ec:next_p()
                    local prev_len = M.count_chars(ec.stl)
                    local cur_len = M.count_chars(ec:eval())
                    saved_chars = saved_chars + (prev_len - cur_len)
                end

                if stl_max_len - saved_chars <= winw then
                    get_out = true
                    break
                end
                i = i + 1
            end
            if get_out then
                break
            end
        end
    end
end

return M
