
code = [[
local friend
if true
  x = "yes"
  if another
    world
  elseif "plus"
    5
  elseif "bust"
    5
  else
    "no"
]]

parse = require "moonscript.parse"
out = assert parse.string code

require("moon").p out

import Block from require "moonscript.javascript.compile"

b = Block!

for s in *out
  b\append_statement s

print b\render!

