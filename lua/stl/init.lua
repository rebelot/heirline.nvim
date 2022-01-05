local M = {}

function M.eval(statusline)
    local stl = {}

    for i, block in ipairs(statusline) do
        block.index = i
        table.insert(stl, M.eval_block(block))
    end

    return table.concat(stl)
end

function M.eval_block(block)
    local stl = {}
    block.hl = block.hl or {} -- function or table

    if block.init then block:init() end

    for i, component in ipairs(block) do
        component.index = i
        component.block = block
        table.insert(stl, M.eval_component(component))
    end

    return table.concat(stl)
end

function M.eval_component(component)
    component.hl = component.hl or {} -- function or table
    component.condition = component.condition or component.block.condition or function() return true end

    if component.init then component:init() end

    if not component:condition() then return "" end

    local provider_str = type(component.provider) == "function" and (component:provider() or "") or (component.provider or "") -- string or ""

    local component_hl = type(component.hl) == "function" and component:hl() or component.hl -- table
    local block_hl = type(component.block.hl) == "function" and component.block:hl() or component.block.hl -- table
    local hl = vim.tbl_extend("force", block_hl, component_hl) -- table

    local hl_str_start, hl_str_end = M.eval_hl(hl)

    return hl_str_start .. provider_str .. hl_str_end
end

function M.eval_hl(hl)
    if vim.tbl_isempty(hl) then
        return "", ""
    else
        if not M.defined_highlights[hl.name] then
            M.make_hl(hl)
        end
        return "%#" .. hl.name .. "#", "%*"
    end
end

M.defined_highlights = {}

function M.make_hl(hl)
    local name = hl.name
    if hl.link then
        vim.cmd("highlight! link " .. name .. " " .. hl.link)
    else
        local fg = hl.fg and "guifg=" .. hl.fg .. " " or ""
        local bg = hl.bg and "guibg=" .. hl.bg .. " " or ""
        local style = hl.style and "gui=" .. hl.style .. " " or ""
        local guisp = hl.guisp and "guisp=" .. hl.guisp .. " " or ""
        if fg or bg or style or guisp then
            vim.cmd("highlight " .. name .. " " .. fg .. bg .. style .. guisp)
        end
    end
    table.insert(M.defined_highlights, hl.name)
end

function M.load()
    vim.cmd("set statusline=%{%v:lua.require'stl'.statusline()%}")
end

M.statuslines = {}

function M.setup(config)
    M.statuslines = config.statuslines
    M.load()
end

function M.statusline()
    for _, statusline in ipairs(M.statuslines) do
        if statusline:condition() then
            return M.eval(statusline)
        end
    end
end

return M
