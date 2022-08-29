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
    return require("heirline.highlights").load_colors(colors)
end

function M.clear_colors()
    return require("heirline.highlights").clear_colors()
end

local function setup_local_winbar_with_autocmd()
    local augrp_id = vim.api.nvim_create_augroup("Heirline_init_winbar", { clear = true })
    vim.api.nvim_create_autocmd({ "VimEnter", "BufWinEnter" }, {
        callback = function()
            if vim.api.nvim_win_get_height(0) > 1 then
                vim.opt_local.winbar = "%{%v:lua.require'heirline'.eval_winbar()%}"
                vim.api.nvim_exec_autocmds("User", { pattern = "HeirlineInitWinbar", modeline = false })
            end
        end,
        group = augrp_id,
        desc = "Heirline: set window-local winbar",
    })
end

---Setup statusline and winbar
---@param statusline table
---@param winbar? table
---@param tabline? table
function M.setup(statusline, winbar, tabline)
    vim.g.qf_disable_statusline = true
    vim.api.nvim_create_augroup("Heirline_update_autocmds", { clear = true })
    M.reset_highlights()

    M.statusline = StatusLine:new(statusline)
    vim.o.statusline = "%{%v:lua.require'heirline'.eval_statusline()%}"

    if winbar then
        M.winbar = StatusLine:new(winbar)
        setup_local_winbar_with_autocmd()
    end

    if tabline then
        M.tabline = StatusLine:new(tabline)
        vim.o.showtabline = 2
        vim.o.tabline = "%{%v:lua.require'heirline'.eval_tabline()%}"
    end
end

local function _eval(statusline)
    statusline.winnr = 1
    statusline.flexible_components = {}
    statusline._buflist = {}
    local out = statusline:eval()
    local buflist = statusline._buflist[1]

    -- flexible components adapting to full-width buflist, shrinking them to the maximum if greater than vim.o.columns
    utils.expand_or_contract_flexible_components(statusline.flexible_components, true, out)

    if buflist then
        out = statusline:traverse() -- this is now the tabline, after expansion/contraction
        -- the space to render the buflist is "columns - (all_minus_fullwidthbuflist)"
        buflist._maxwidth = vim.o.columns - (utils.count_chars(out) - utils.count_chars(buflist:traverse()))
        utils.page_buflist(buflist)
        out = statusline:traverse()

        -- now the buflist is paged, and flexible components still have the same value, however, there might be more space now, depending on the page
        utils.expand_or_contract_flexible_components(statusline.flexible_components, true, out) -- flexible components are re-adapting to paginated buflist
    end
    return statusline:traverse()
end

---@return string
function M.eval_statusline()
    return _eval(M.statusline)
end

---@return string
function M.eval_winbar()
    return _eval(M.winbar)
end

---@return string
function M.eval_tabline()
    return _eval(M.tabline)
end


-- test [[
function M.timeit()
    local start = os.clock()
    M.eval_statusline()
    M.eval_winbar()
    M.eval_tabline()
    return os.clock() - start
end

--]]

return M
