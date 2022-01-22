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
    for i, child in ipairs(children) do
        local new_child = M.clone(child)
        table.insert(new, new_child)
    end
    return new
end

function M.count_chars(str)
    str = vim.api.nvim_eval_statusline(str:gsub("%%=", ""), { winid = 0 }).str
    local non_ascii_bytes = 0
    local ascii_bytes = 0
    for c in string.gmatch(str, ".") do
        if c:byte() > 127 then
            non_ascii_bytes = non_ascii_bytes + 1
        else
            ascii_bytes = ascii_bytes + 1
        end
    end
    return ascii_bytes + non_ascii_bytes / 3
end

function M.set_win_attr(self, attr, val, default)
    local winnr = vim.api.nvim_win_get_number(0)
    self[attr] = self[attr] or {}
    self[attr][winnr] = val or (self[attr][winnr] or default)
end

function M.get_win_attr(self, attr, default)
    local winnr = vim.api.nvim_win_get_number(0)
    self[attr] = self[attr] or {}
    self[attr][winnr] = self[attr][winnr] or default
    return self[attr][winnr]
end

function M.make_elastic_component(priority, providers)
    local new = {}
    new.static = {
        priority = priority,
        providers = providers,
        next_p = function(self)
            local pi = M.get_win_attr(self, "pi") + 1
            if pi > #self.providers then
                pi = #self.providers
            end
            M.set_win_attr(self, "pi", pi)
        end,
    }
    new.init = function(self)
        if not self.once then
            self.elastic_ids[self.priority] = self.elastic_ids[self.priority] or {}
            table.insert(self.elastic_ids[self.priority], self.id)
            M.set_win_attr(self, "pi", 1)
            self.once = true
        end
    end

    new.condition = function(self)
        return not self.deferred
    end

    new.provider = function(self)
        local pi = M.get_win_attr(self, "pi")
        local provider = self.providers[pi]
        return type(provider) == 'function' and (provider(self) or "") or provider
    end

    return new
end

local function elastic_len(statusline, reset)
    local len = 0
    for _, ids in ipairs(statusline.elastic_ids) do
        for _, id in ipairs(ids) do
            local ec = statusline:get(id)
            if reset then
                M.set_win_attr(ec, "pi", 1)
            end
            len = len + M.count_chars(ec:eval())
        end
    end
    return len
end

local function defer(statusline, val)
    for _, ids in ipairs(statusline.elastic_ids) do
        for _, id in ipairs(ids) do
            local ec = statusline:get(id)
            ec.deferred = val
        end
    end
end

function M.elastic_before(statusline, last_out)
    local winw = vim.api.nvim_win_get_width(0)
    statusline.elastic_ids = statusline.elastic_ids or {}

    defer(statusline, true)
    local avail_wo_elastic = winw - M.count_chars(statusline:eval())
    defer(statusline, false)

    local avail = avail_wo_elastic - elastic_len(statusline, true) -- resets pi to 1

    if avail < 1 then
        local stop = false
        for _, ids in ipairs(statusline.elastic_ids) do
            local max_count = 0
            for _, id in ipairs(ids) do
                local ec = statusline:get(id)
                max_count = max_count + #ec.providers
            end

            local i = 0
            while i <= max_count do
                for _, id in ipairs(ids) do
                    local ec = statusline:get(id)
                    ec:next_p()
                end

                if avail_wo_elastic - elastic_len(statusline, false) > 0 then
                    stop = true
                    break
                end
                i = i + 1
            end
            if stop then
                break
            end
        end
    end
end

return M
