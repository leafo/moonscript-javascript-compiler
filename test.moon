
-- "one"
-- "two"
-- "trhee"
-- "trheefeifefjlwefjkwfklwfjlwkeafklwejf"

-- this isn't done  yet
-- a.b = c

code = [[
x = [a for a in *things]
]]

parse = require "moonscript.parse"
out = assert parse.string code

print "Before"
print "============"
require("moon").p out

transform = require("moonscript.javascript.transform")

out = transform.tree\transform out

print "After"
print "============"

import Block from require "moonscript.javascript.compile"

b = Block!

for s in *out
  b\append_statement s

print b\render!


