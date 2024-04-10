local M = {}

---@type table<string, string|integer>
local loaded_colors = {}

---@type nil | fun():table<string, string|integer>
local deferred_load_colors = nil

local function load(colors)
    for c, v in pairs(colors) do
        loaded_colors[c] = v
    end
end

---@param colors table<string, string|integer> | fun():table<string, string|integer>
function M.load(colors)
    if type(colors) == "function" then
        deferred_load_colors = function()
            load(colors())
            deferred_load_colors = nil
        end
    else
        load(colors)
    end
end

---@return table<string, string|integer> loaded_colors
function M.get()
    if deferred_load_colors then
        deferred_load_colors()
    end
    return loaded_colors
end

function M.clear()
    loaded_colors = {}
end

return M
