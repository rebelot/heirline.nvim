local eq = assert.equals

local h = require("heirline")
local u = require("heirline.utils")
local cond = require("heirline.conditions")
local eval = function(winid)
    winid = winid or 0
    return vim.api.nvim_eval_statusline(vim.o.statusline, { winid = winid, maxwidth = 0 }).str
end
local win_getid = function(nr)
    local id = vim.fn.win_getid(nr)
    return id > 0 and id or error("window number not found")
end

local a = { provider = string.rep("A", 40) }
local b = { provider = string.rep("B", 30) }
local c = { provider = string.rep("C", 20) }
local d = { provider = string.rep("D", 10) }
local e = { provider = string.rep("E", 5) }
local f = { provider = string.rep("F", 2) }
local null = { provider = "" }
local space = { provider = " " }
local fill = { provider = "%=" }

describe("Flexible components", function()
    it("works on single component", function()
        vim.cmd("wincmd o")
        h.setup({ flexible = 1, a, b }) -- 40; 30
        vim.o.laststatus = 2
        eq(40, #eval())
        vim.cmd("wincmd 39v")
        eq(30, #eval())
        vim.cmd("wincmd 40|")
        eq(40, #eval())
    end)

    it("works on nested components", function()
        vim.cmd("wincmd o")
        h.setup({
            flexible = 1,
            a,
            { flexible = true, b, c },
            {
                { flexible = true, e, f },
                { flexible = true, e, f },
            },
            f,
        }) -- 40; 30

        vim.o.laststatus = 2
        eq(40, #eval())
        vim.cmd("wincmd 39v")
        eq(30, #eval())
        vim.cmd("wincmd 29|")
        eq(20, #eval())
        vim.cmd("wincmd 19|")
        eq(10, #eval())
        vim.cmd("wincmd 9|")
        eq(4, #eval())
        vim.cmd("wincmd 3|")
        eq(2, #eval())

        vim.cmd("wincmd 9|")
        eq(4, #eval())
        vim.cmd("wincmd 19|")
        eq(10, #eval())
        vim.cmd("wincmd 29|")
        eq(20, #eval())
        vim.cmd("wincmd 39v")
        eq(30, #eval())
        vim.cmd("wincmd 40v")
        eq(40, #eval())
    end)

    it("works on nested components (using deprecated util)", function()
        vim.cmd("wincmd o")
        h.setup({
            u.make_flexible_component(1, a, u.make_flexible_component(nil, b, c), {
                u.make_flexible_component(nil, e, f),
                u.make_flexible_component(nil, e, f),
            }, f),
        }) -- 40; 30

        vim.o.laststatus = 2
        eq(40, #eval())
        vim.cmd("wincmd 39v")
        eq(30, #eval())
        vim.cmd("wincmd 29|")
        eq(20, #eval())
        vim.cmd("wincmd 19|")
        eq(10, #eval())
        vim.cmd("wincmd 9|")
        eq(4, #eval())
        vim.cmd("wincmd 3|")
        eq(2, #eval())

        vim.cmd("wincmd 9|")
        eq(4, #eval())
        vim.cmd("wincmd 19|")
        eq(10, #eval())
        vim.cmd("wincmd 29|")
        eq(20, #eval())
        vim.cmd("wincmd 39v")
        eq(30, #eval())
        vim.cmd("wincmd 40v")
        eq(40, #eval())
    end)
    vim.cmd("wincmd o")
end)

describe("Updatable components", function()
    it("Updates on autocmd", function()
        vim.cmd("wincmd o")
        local provider = "one"
        h.setup({
            provider = function()
                return provider
            end,
            update = {
                "User",
                pattern = "TestUpdate",
            },
        })
        eq("one", eval())
        provider = "two"
        eq("one", eval())
        vim.cmd("doautocmd User TestUpdate")
        eq("two", eval())
        vim.cmd("au! User TestUpdate")
    end)
end)

describe("Update and flexible", function()
    it("updates on different windows (direct)", function()
        vim.cmd("wincmd o")

        local flex = { flexible = 1, a, b }
        flex.update = { "User", pattern = "TestUpdate" }
        h.setup(flex)

        eq(40, #eval())

        vim.cmd("wincmd 39v")
        eq(40, #eval(win_getid(1)))
        eq(40, #eval(win_getid(2)))

        vim.cmd("doautocmd User TestUpdate")
        eq(30, #eval(win_getid(1)))
        eq(40, #eval(win_getid(2)))

        vim.cmd("wincmd 45|")
        eq(30, #eval(win_getid(1)))
        eq(40, #eval(win_getid(2)))

        vim.cmd("doautocmd User TestUpdate")
        eq(40, #eval(win_getid(1)))
        eq(30, #eval(win_getid(2)))

        vim.cmd("au! User TestUpdate")
    end)

    it("updates on different windows (wrapped)", function()
        vim.cmd("wincmd o")

        local flex = { { flexible = 1, a, b }, update = { "User", pattern = "TestUpdate" } }
        h.setup(flex)

        eq(40, #eval())

        vim.cmd("wincmd 39v")
        eq(40, #eval(win_getid(1)))
        eq(40, #eval(win_getid(2)))

        vim.cmd("doautocmd User TestUpdate")
        eq(30, #eval(win_getid(1)))
        eq(40, #eval(win_getid(2)))

        vim.cmd("wincmd 45|")
        eq(30, #eval(win_getid(1)))
        eq(40, #eval(win_getid(2)))

        vim.cmd("doautocmd User TestUpdate")
        eq(40, #eval(win_getid(1)))
        eq(30, #eval(win_getid(2)))

        vim.cmd("au! User TestUpdate")
    end)

    it("updatable as flex child", function()
        vim.cmd("wincmd o")
        local provider = "AAA"
        h.setup({
            flexible = 1,
            {
                provider = function()
                    return "AAA" .. provider
                end,
                update = { "User", pattern = "TestUpdate" },
            },
            {
                provider = function()
                    return provider
                end,
                update = { "User", pattern = "TestUpdate" },
            },
        })
        eq(6, #eval())
        vim.cmd("wincmd 5v")
        eq(3, #eval(win_getid(1)))
        eq(6, #eval(win_getid(2)))

        provider = "BBB"
        eq("AAA", eval(win_getid(1)))
        eq("AAAAAA", eval(win_getid(2)))

        vim.cmd("doautocmd User TestUpdate")
        eq("BBB", eval(win_getid(1)))
        eq("AAABBB", eval(win_getid(2)))
        vim.cmd("au! User TestUpdate")
    end)
end)
