local M = {}
local StatusLine = require'heirline.statusline'

function M.reset_highlights()
    return require'heirline.highlights'.reset_highlights()
end

function M.load()
    vim.g.qf_disable_statusline = true
    vim.cmd("set statusline=%{%v:lua.require'heirline'.eval()%}")
end

function M.setup(statusline)
    M.statusline = StatusLine:new(statusline)
    M.statusline:make_ids()
    M.load()
end

function M.eval()
    return M.statusline:eval()
end

return M
