local M = {}

function M.is_active()
    local winid = vim.api.nvim_get_current_win()
    local curwin = tonumber(vim.g.actual_curwin)
    return winid == curwin
end

function M.buffer_matches(list)
    local buf = vim.api.nvim_get_current_buf()
    for k, v in pairs(list) do
        if k == 'filetype' or k == 'buftype' then
            local opt = vim.api.nvim_buf_get_option(buf, k)
            if vim.tbl_contains(v, opt) then
                return true
        end
        elseif k == 'bufname' then
            local bufname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
            for _, pattern in ipairs(v) do
                local match = bufname:find(pattern)
                if match then return true end
            end
        end
    end
    return false
end

function M.width_percent_below(n, thresh)
    local winwidth = vim.api.nvim_win_get_width(0)
    return n / winwidth <= thresh
end

function M.is_git_repo()
    return vim.b.gitsigns_head or vim.b.gitsigns_status_dict
end

function M.has_diagnostics()
    return #vim.diagnostics.get(0) > 0
end

function M.lsp_attached()
    return #vim.lsp.buf_get_clients() > 0
end


return M
