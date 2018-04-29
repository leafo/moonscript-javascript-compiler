
import Block from require "moonscript.javascript.compile"

describe "moonscript.javascript.compile", ->
  examples = {
    {
      "hello = 'world'"
      [[
var hello;
hello = 'world';]]
    }

    {
      [[
hello = 'world'
a = c]]
      [[
var hello, a;
hello = 'world';
a = c;]]
    }

    {
      [[
if something
  x = "cool"]]
      [[
var x;
if (something) {
  x = "cool";
}]]
    }

    {
      [[
hello = "world"
if something
  x = "cool"
elseif dork
  y = "cool"
else
  z = 10 + 2
]]
  
      [[
var hello, x, y, z;
hello = "world";
if (something) {
  x = "cool";
} else if (dork) {
  y = "cool";
} else {
  z = 10 + 2;
}]]
    }

    {
      [[
for thing in *items
  print thing]]
      [[
var idx, thing;
for (var idx = 0; idx <= items.length - 1; idx++) {
  thing = items[idx];
  print(thing);
}]]
    }
  }

  for {input, output, :name} in *examples
    it name or "compiles `#{input\match "^[^\n]+"}`", ->
      parse = require "moonscript.parse"
      tree = assert parse.string input

      transform = require("moonscript.javascript.transform")
      tree = transform.tree\transform tree

      b = Block!
      for s in *tree
        b\append_statement s

      assert.same output, b\render!


