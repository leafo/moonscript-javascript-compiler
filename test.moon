
-- "one"
-- "two"
-- "trhee"
-- "trheefeifefjlwefjkwfklwfjlwkeafklwejf"

-- this isn't done  yet
-- a.b = c

code = [[
hello = "world"
if something
  x = "cool"
elseif dork
  y = "cool"
else
  z = 10 + 2
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


