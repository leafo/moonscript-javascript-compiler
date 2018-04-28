
code = [[
-- one.two.three
-- one(2, "snake head")
-- dad.zone.umm(true)\okay
a b c d e f!
]]

parse = require "moonscript.parse"
out = assert parse.string code

require("moon").p out

import Block from require "moonscript.javascript.compile"

b = Block!

for s in *out
  b\append_statement s

print b\render!

