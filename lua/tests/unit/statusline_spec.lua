local eq = assert.equals
local ne = assert.is_not.equals

local h = require("heirline")
local s = require("heirline.statusline")

describe('Object creation', function()
    it('is a new object', function()
        local o = {}
        local n = s:new(o)
        ne(tostring(n), tostring(o))
    end)
end)

