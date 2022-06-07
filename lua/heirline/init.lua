local M = {}
local StatusLine = require("heirline.statusline")
local utils = require("heirline.utils")

function M.reset_highlights()
    return require("heirline.highlights").reset_highlights()
end

function M.get_highlights()
    return require("heirline.highlights").get_highlights()
end

function M.load_colors(colors)
    return require("heirline.highlights").load_colors(colors)
end

function M.clear_colors()
    return require("heirline.highlights").clear_colors()
end

local function setup_local_winbar_with_autocmd()
    local augrp_id = vim.api.nvim_create_augroup("Heirline_init_winbar", { clear = true })
    vim.api.nvim_create_autocmd("BufWinEnter", {
        callback = function()
            vim.opt_local.winbar = "%{%v:lua.require'heirline'.eval_winbar()%}"
            vim.api.nvim_exec_autocmds('User', {pattern = 'HeirlineInitWinbar', modeline = false})
        end,
        group = augrp_id,
        desc = "Heirline: set window-local winbar",
    })
end

function M.setup(statusline, winbar)
    vim.g.qf_disable_statusline = true
    vim.api.nvim_create_augroup("Heirline_update_autocmds", { clear = true })
    M.reset_highlights()

    M.statusline = StatusLine:new(statusline)
    vim.o.statusline = "%{%v:lua.require'heirline'.eval_statusline()%}"
    if winbar then
        M.winbar = StatusLine:new(winbar)
        setup_local_winbar_with_autocmd()
    end
end

function M.eval_statusline()
    M.statusline.winnr = vim.api.nvim_win_get_number(0)
    M.statusline.flexible_components = {}
    local out = M.statusline:eval()
    utils.expand_or_contract_flexible_components(M.statusline, false, out)
    return out
end

function M.eval_winbar()
    M.winbar.winnr = vim.api.nvim_win_get_number(0)
    M.winbar.flexible_components = {}
    local out = M.winbar:eval()
    utils.expand_or_contract_flexible_components(M.winbar, true, out)
    return out
end

-- test [[
function M.timeit()
    local start = os.clock()
    M.eval_statusline()
    M.eval_winbar()
    return os.clock() - start
end

--]]

return M
