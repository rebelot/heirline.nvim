local M = {}
local StatusLine = require'heirline.statusline'

function M.reset_highlights()
    return require'heirline.highlights'.reset_highlights()
end

function M.load()
    vim.g.qf_disable_statusline = true
    vim.cmd("set statusline=%{%v:lua.require'heirline'.eval()%}")
end

function M.setup(statusline, events)
    M.statusline = StatusLine:new(statusline)
    M.statusline:make_ids()
    M.events = events or {}
    M.load()
end

local last_out = ""
function M.eval()
    if M.events.before then
        M.events.before(M.statusline, last_out)
    end
    local out = M.statusline:eval()
    if M.events.after then
        out = M.events.after(M.statusline, out)
    end
    last_out = out
    return out
end

return M
