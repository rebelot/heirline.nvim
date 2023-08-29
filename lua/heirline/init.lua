local M = {}
local StatusLine = require("heirline.statusline")
local utils = require("heirline.utils")

function M.reset_highlights()
    return require("heirline.highlights").reset_highlights()
end

function M.get_highlights()
    return require("heirline.highlights").get_highlights()
end

---Load color aliases
---@param colors table<string, string|integer>
---@return nil
function M.load_colors(colors)
    colors = type(colors) == "function" and colors() or colors
    return require("heirline.highlights").load_colors(colors)
end

function M.clear_colors()
    return require("heirline.highlights").clear_colors()
end

local function setup_local_winbar_with_autocmd(callback)
    local augrp_id = vim.api.nvim_create_augroup("Heirline_init_winbar", { clear = true })
    vim.api.nvim_create_autocmd({ "VimEnter", "UIEnter", "BufWinEnter", "FileType", "TermOpen" }, {
        callback = function(args)
            local heirline_winbar = "%{%v:lua.require'heirline'.eval_winbar()%}"
            if args.event == "VimEnter" or args.event == "UIEnter" then
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                    local winbuf = vim.api.nvim_win_get_buf(win)
                    local new_args = vim.deepcopy(args)
                    new_args.buf = winbuf
                    if callback and callback(new_args) == true then
                        if vim.wo[win].winbar == heirline_winbar then
                            vim.wo[win].winbar = nil
                        end
                    else
                        vim.wo[win].winbar = heirline_winbar
                    end
                end
            end
            if callback and callback(args) == true then
                if vim.opt_local.winbar:get() == heirline_winbar then
                    vim.opt_local.winbar = nil
                end
                return
            end

            -- local wins = vim.tbl_filter(function(win)
            --     return vim.api.nvim_win_get_buf(win) == args.buf
            -- end, vim.api.nvim_list_wins())

            -- if vim.api.nvim_win_get_config(wins[0] or 0).zindex then
            -- if vim.api.nvim_win_get_config(0).zindex then
            --     vim.opt_local.winbar = nil
            --     return
            -- end

            if vim.api.nvim_win_get_height(0) > 1 then
                vim.opt_local.winbar = heirline_winbar
            end
        end,
        group = augrp_id,
        desc = "Heirline: set window-local winbar",
    })
end

---Setup
---@param config {statusline: StatusLine, winbar: StatusLine, tabline: StatusLine, statuscolumn: StatusLine, opts: table}
function M.setup(config)
    vim.g.qf_disable_statusline = true
    vim.api.nvim_create_augroup("Heirline_update_autocmds", { clear = true })
    M.reset_highlights()

    local opts = config.opts or {}

    if opts.colors then
        M.load_colors(opts.colors)
    end

    if config.statusline then
        M.statusline = StatusLine:new(config.statusline)
        vim.o.statusline = "%{%v:lua.require'heirline'.eval_statusline()%}"
    end

    if config.winbar then
        M.winbar = StatusLine:new(config.winbar)
        setup_local_winbar_with_autocmd(opts.disable_winbar_cb)
    end

    if config.tabline then
        M.tabline = StatusLine:new(config.tabline)
        vim.o.tabline = "%{%v:lua.require'heirline'.eval_tabline()%}"
    end

    if config.statuscolumn then
        M.statuscolumn = StatusLine:new(config.statuscolumn)
        vim.o.statuscolumn = "%{%v:lua.require'heirline'.eval_statuscolumn()%}"
    end
end

---comment
---@param statusline StatusLine
---@param winnr integer
---@param full_width boolean
---@return string
local function _eval(statusline, winnr, full_width)
    statusline.winnr = winnr
    statusline._flexible_components = {}
    statusline._updatable_components = {}
    statusline._buflist = {}
    local out = statusline:eval()
    local buflist = statusline._buflist[1]

    -- flexible components adapting to full-width buflist, shrinking them to the maximum if greater than vim.o.columns
    statusline:expand_or_contract_flexible_components(full_width, out)

    if buflist then
        out = statusline:traverse() -- this is now the tabline, after expansion/contraction
        -- the space to render the buflist is "columns - (all_minus_fullwidthbuflist)"
        local maxwidth = (full_width and vim.o.columns) or vim.api.nvim_win_get_width(0)
        maxwidth = maxwidth - (utils.count_chars(out) - utils.count_chars(buflist:traverse()))
        utils.page_buflist(buflist, maxwidth)
        out = statusline:traverse()

        -- now the buflist is paged, and flexible components still have the same value, however, there might be more space now, depending on the page
        statusline:expand_or_contract_flexible_components(full_width, out) -- flexible components are re-adapting to paginated buflist
    end

    statusline:_freeze_cache()
    return statusline:traverse()
end

---@return string
function M.eval_statusline()
    local winnr = vim.api.nvim_win_get_number(0)
    return _eval(M.statusline, winnr, vim.o.laststatus == 3)
end

---@return string
function M.eval_winbar()
    local winnr = vim.api.nvim_win_get_number(0)
    return _eval(M.winbar, winnr, false)
end

---@return string
function M.eval_tabline()
    local winnr = 1
    return _eval(M.tabline, winnr, true)
end

--
---@return string
function M.eval_statuscolumn()
    return M.statuscolumn:eval()
end

local function timeit(func, args)
    local start = os.clock()
    func(unpack(args))
    return os.clock() - start
end

function M.timeit(ntimes)
    ntimes = ntimes or 1000
    local func_map = {
        statusline = M.statusline and M.eval_statusline,
        winbar = M.winbar and M.eval_winbar,
        tabline = M.tabline and M.eval_tabline,
        statuscolumn = M.statuscolumn and M.eval_statuscolumn,
    }
    local tot_time = 0
    print("Average times over", ntimes, "runs:")
    for name, func in pairs(func_map) do
        local time = 0
        for _ = 1, ntimes do
            time = time + timeit(func, {})
        end
        local avg_time = time / ntimes
        tot_time = tot_time + avg_time
        print(string.format("%s: %.3f ms", name, avg_time * 1000))
    end
    print(string.format("total: %.3f ms", tot_time * 1000))
end

return M
