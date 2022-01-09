local M = {}

M.git = {}
M.diag = {}
M.buf = {}
M.lsp = {}


function M.git.added()
    local icon = vim.fn.sign_getdefined('GitSignsAdd')[1].text
    local dict = vim.b.gitsigns_status_dict
    return dict.added
end

function M.git.removed()
    local icon = vim.fn.sign_getdefined('GitSigns')[1].text
    local dict = vim.b.gitsigns_status_dict
    return dict.removed
end

function M.git.changed()
    local dict = vim.b.gitsigns_status_dict
    return dict.removed
end

function M.git.branch()
    local dict = vim.b.gitsigns_status_dict
    return dict.head
end

function M.diag.error()
    local count = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
    return count > 0 and count
end

function M.diag.warning()
    local count = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
    return count > 0 and count

end

function M.diag.info()
    local count = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
    return count > 0 and count

end

function M.diag.hint()
    local count = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
    return count > 0 and count
end



return M

