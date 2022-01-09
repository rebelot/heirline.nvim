local Stl = require'stl'.StatusLine
local a = { provider = function(self) return self.x or "" end }
-- local b = { {provider = 'xx'}, {provider = 'yy'}}
-- local c = { provider = 'ww' }

s1 = { {init = function(self) self.x = 1 end, a}}
s2 = { init = function(self) self.x = 2 end, a}

s = {s1, s2}
S = Stl:new(s)
