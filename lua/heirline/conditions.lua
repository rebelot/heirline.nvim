local M = {}

function M.is_active()
    local winid = vim.api.nvim_get_current_win()
    local curwin = tonumber(vim.g.actual_curwin)
    return winid == curwin
end

function M.is_not_active()
    return not M.is_active()
end

local function pattern_list_matches(str, pattern_list)
    for _, pattern in ipairs(pattern_list) do
        if str:find(pattern) then
            return true
        end
    end
    return false
end

local buf_matchers = {
    filetype = function(bufnr)
        return vim.bo[bufnr].filetype
    end,
    buftype = function(bufnr)
        return vim.bo[bufnr].buftype
    end,
    bufname = function(bufnr)
        return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
    end,
}

function M.buffer_matches(patterns, bufnr)
    bufnr = bufnr or 0
    for kind, pattern_list in pairs(patterns) do
        if pattern_list_matches(buf_matchers[kind](bufnr), pattern_list) then
            return true
        end
    end
    return false
end

function M.width_percent_below(n, thresh, is_winbar)
    local winwidth
    if vim.o.laststatus == 3 and not is_winbar then
        winwidth = vim.o.columns
    else
        winwidth = vim.api.nvim_win_get_width(0)
    end

    return n / winwidth <= thresh
end

function M.is_git_repo()
    return vim.b.gitsigns_head or vim.b.gitsigns_status_dict
end

function M.has_diagnostics()
    return #vim.diagnostic.get(0) > 0
end

function M.lsp_attached()
    return next(vim.lsp.buf_get_clients()) ~= nil
end

return M
