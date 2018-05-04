
import Block from require "moonscript.javascript.compile"

describe "moonscript.javascript.transform", ->
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
var _i, thing;
for (_i = 0; _i <= items.length - 1; _i++) {
  thing = items[_i];
  print(thing);
}]]
    }

    {
      [[one two
three four]]
      [[one(two);
return three(four);]]
    }

      {
        [[
if one
  10
elseif true
  "yes"
else
  20]]
        [[
if (one) {
  return 10;
} else if (true) {
  return "yes";
} else {
  return 20;
}]]
      }

    {
      [[m = "tw"
x = ->
  g = 100
  if something
    k = "nine"
    "yes"
  else
    f = 232
    "no"]]
      [[
var m, x;
m = "tw";
x = function() {
  var g, k, f;
  g = 100;
  if (something) {
    k = "nine";
    return "yes";
  } else {
    f = 232;
    return "no";
  }
}]]
    }
    {
      [[
m = "tw"
x = ->
  g = 100
  if something
    "yes"
  else
    f = 232
    "no"]]
      [[
var m, x;
m = "tw";
x = function() {
  var g, f;
  g = 100;
  if (something) {
    return "yes";
  } else {
    f = 232;
    return "no";
  }
}]]
    }

    {
      [[
f = (a,b) ->
  b = "no"
  a]]
    [[
var f;
f = function(a, b) {
  b = "no";
  return a;
}]]
    }

    {
      [[
f = (a,b) ->
  b = "no"
  k = "another"
  a = b + k
  return]]
      [[
var f;
f = function(a, b) {
  var k;
  b = "no";
  k = "another";
  a = b + k;
  return;
}]]
    }
    {
      [[
b = "what"
a = "another"
f = (b) ->
  a = "world"
  b = "zone"
  c = "okay"]]
      [[
var b, a, f;
b = "what";
a = "another";
f = function(b) {
  var c;
  a = "world";
  b = "zone";
  c = "okay";
}]]
    }

    {
      [[
f = "test"
local f
local m
f = "please"
m = "hi"]]
      [[
var f;
f = "test";
var f;
var m;
f = "please";
m = "hi";]]
    }
    {
      [[
_i = "Yo"
summer = "fun"
f = ->
  g = thing
  for thing in *things
    summer = "no fun" + thing
    for item in *items
      "ok"]]

      [[
var _i, summer, f;
_i = "Yo";
summer = "fun";
f = function() {
  var g, _i_1, thing, _i_2, item;
  g = thing;
  for (_i_1 = 0; _i_1 <= things.length - 1; _i_1++) {
    thing = things[_i_1];
    summer = "no fun" + thing;
    for (_i_2 = 0; _i_2 <= items.length - 1; _i_2++) {
      item = items[_i_2];
      "ok";
    }
  }
}]]
    }

    {
      [[
while a > 5
  k = 100
  console.log "got it!"]]
      [[
var k;
while (a > 5) {
  k = 100;
  console.log("got it!");
}]]
    }

    {
      [[
print if something
  k = 100
  "world"]]
      [[
var k;
return print((function() {
  if (something) {
    k = 100;
    return "world";
  }
})());]]
    }

    {
      [[
m = {
  world: if something
    f = "good"
}

print if something
  k = 100]]
      [[
var m, f, k;
m = {
  world: (function() {
    if (something) {
      f = "good";
    }
  })()
};
return print((function() {
  if (something) {
    k = 100;
  }
})());]]
    }
    {
      'x = [a for a in *things]'
      [[
var x;
x = (function() {
  var _accum, _i, a;
  _accum = [];
  for (_i = 0; _i <= things.length - 1; _i++) {
    a = things[_i];
    _accum.push(a);
  }
  return _accum;
})();]]
    }
    {
      'x = [a for a=1,3]'
      [[var x;
x = (function() {
  var _accum, a;
  _accum = [];
  for (a = 1; a <= 3; a++) {
    _accum.push(a);
  }
  return _accum;
})();]]
    }
    {
      'f = [x + y for x in *first for y in *second]'
      [[
var f;
f = (function() {
  var _accum, _i, x, _i_1, y;
  _accum = [];
  for (_i = 0; _i <= first.length - 1; _i++) {
    x = first[_i];
    for (_i_1 = 0; _i_1 <= second.length - 1; _i_1++) {
      y = second[_i_1];
      _accum.push(x + y);
    }
  }
  return _accum;
})();]]
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


