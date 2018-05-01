
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


