
import Block from require "moonscript.javascript.compile"

describe "moonscript.javascript.compile", ->
  examples = {
    {
      "what"
      "what;"
    }
    {
      "x = y"
      "x = y;"
    }

    {
      "local friend"
      "var friend;"
    }

    {
      "local one, two"
      "var one, two;"
    }

    {
      "a = 3 + 4"
      "a = 3 + 4;"
    }

    {
      [[if true then "okay"]]
      [[
if (true) {
  "okay";
}]]
    }

    {
      [[
if 4 + 2
  3343
else
  "sure"]]

      [[
if (4 + 2) {
  3343;
} else {
  "sure";
}]]
    }

    {
      [[
if one
  if another
    world
  else
    true
elseif "plus"
  "negative"
else
  null]]

  [[
if (one) {
  if (another) {
    world;
  } else {
    true;
  }
} else if ("plus") {
  "negative";
} else {
  null;
}]]
    }

    {
      [[hello "world"]]
      [[hello("world");]]
    }

    {
      [[hello a, b, c, 1, 23,4, another(1)]]
      [[hello(a, b, c, 1, 23, 4, another(1));]]
    }

    {
      [[one(2, "snake head")]]
      [[one(2, "snake head");]]
    }

    {
      [[dad.zone.umm(true).okay]]
      [[dad.zone.umm(true).okay;]]
    }
    {
      [[a b c d e f!]]
      [[a(b(c(d(e(f())))));]]
    }
  }

  for {input, output} in *examples
    it "compiles `#{input\match "^[^\n]+"}`", ->
      parse = require "moonscript.parse"
      tree = assert parse.string input
      b = Block!
      for s in *tree
        b\append_statement s

      assert.same b\render!, output


