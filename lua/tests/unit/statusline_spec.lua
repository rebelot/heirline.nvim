local eq = assert.equals

local h = require("heirline")
local s = require("heirline.statusline")

describe('Object creation', function()
    it('loses references with new object', function()
        local o = { foo = 'bar' }
        local n = s:new(o)
        assert.is_nil(n.foo)
    end)
end)

