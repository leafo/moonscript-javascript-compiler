
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

    {
      [[one = dad.zone.umm(true).okay!]]
      [[one = dad.zone.umm(true).okay();]]
    }

    {
      [[please = hello.world + zone!]]
      [[please = hello.world + zone();]]
    }

    {
      "one.a + two.b + three.c"
      "one.a + two.b + three.c;"
    }

    {
      [[if something.yes then no.way]]
      [[
if (something.yes) {
  no.way;
}]]
    }

    {
      [[if something! then four.times elseif math.floor(5) == 2 then "yeah"]]
      [[
if (something()) {
  four.times;
} else if (math.floor(5) == 2) {
  "yeah";
}]]
    }
    {
      [[
x = ->
  console.log "hello world"
  return "please"]]
      [[
x = function() {
  console.log("hello world");
  return "please";
}]]
    }
    {
      [[y = ->]]
      [[y = function() { }]]
    }
    {
      [[
x = (one, two, three) ->
  return one + two + three]]
      [[
x = function(one, two, three) {
  return one + two + three;
}]]
    }

    {
      [[(-> console.log "what")!]]
      [[
(function() {
  console.log("what");
})();]]
    }
  }

  for {input, output} in *examples
    it "compiles `#{input\match "^[^\n]+"}`", ->
      parse = require "moonscript.parse"
      tree = assert parse.string input
      b = Block!
      for s in *tree
        b\append_statement s

      assert.same output, b\render!


