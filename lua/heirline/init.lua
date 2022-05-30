local M = {}
local StatusLine = require("heirline.statusline")
local utils = require("heirline.utils")

function M.reset_highlights()
    return require("heirline.highlights").reset_highlights()
end

function M.get_highlights()
    return require("heirline.highlights").get_highlights()
end

local au_ids = {}

function M.get_au_ids()
    return au_ids
end

function M.clear_autocommands()
    for i = 1, #au_ids, 1 do
        local au_id = table.remove(au_ids)
        vim.api.nvim_del_autocmd(au_id)
    end
end

function M.load()
    vim.g.qf_disable_statusline = true
    vim.o.statusline = "%{%v:lua.require'heirline'.eval_statusline()%}"
    if M.winbar then
        vim.o.winbar = "%{%v:lua.require'heirline'.eval_winbar()%}"
    end
end

function M.setup(statusline, winbar)
    M.clear_autocommands()
    M.reset_highlights()
    M.statusline = StatusLine:new(statusline)
    if winbar then
        M.winbar = StatusLine:new(winbar)
    end
    M.load()
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
