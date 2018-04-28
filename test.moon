
-- "one"
-- "two"
-- "trhee"
-- "trheefeifefjlwefjkwfklwfjlwkeafklwejf"

code = [[
for item in *items
  print item
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


