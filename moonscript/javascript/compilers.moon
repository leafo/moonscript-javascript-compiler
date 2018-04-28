
import types, BaseType from require "tableshape"
import Line, Block, node from require "moonscript.javascript.compile"

import split_ntuples from require "moonscript.javascript.util"

class Proxy extends BaseType
  new: (@fn) =>
  _transform: (...) => @.fn!\_transform ...
  _describe: (...) => @.fn!\_describe ...

proxy_node = (name) ->
  Proxy ->
    require("moonscript.javascript.compilers")[name]

match_node = (name) ->
  types.shape { name }, open: true

t = (tbl, ...) ->
  tbl[-1] = types.number + types.nil
  types.shape tbl, ...

{
  ref: t({
    "ref"
    types.string\tag "name"
  }) % (val, state) ->
    state.name

  string: t({
    "string"
    types.string\tag "delim"
    types.string\tag "value"
  }) % (val, state) ->
    "#{state.delim}#{state.value}#{state.delim}"

  number: t({
    "number"
    (types.string + types.number)\tag "value"
  }) % (val, state) ->
    tostring state.value

  if: do
    else_node = t({
      "else"
      types.table\tag "block"
    }) % (val, state) ->
      Block " else {", "}", state.block

    else_if_node = t({
      "elseif"
      types.any\tag "cond"
      types.table\tag "block"
    }) % (val, state) ->
      Line(
        " else if ("
        node state.cond
        Block ") {", "}", state.block
      )

    t({
      "if"
      types.any\tag "cond"
      types.table\tag "block"
    }, extra_fields: types.map_of(
      types.number
      types.scope(else_if_node + else_node)\tag "elses[]"
    )) % (val, state) ->
      Line(
        "if ("
        node state.cond
        ") "
        Block "{", "}", state.block
        unpack state.elses or {}
      )

  declare_with_shadows: proxy_node "declare"
  declare: t({
    types.one_of {"declare", "declare_with_shadows"}
    types.array_of(types.string)\tag "names"
  }) % (val, state) ->
    "var #{table.concat state.names, ", "}"
  
  exp: do
    operand = types.scope types.shape({
      types.string\tag "operator"
      (types.any / node)\tag "value"
    }) % (val, state) ->
      Line " #{state.operator} ", state.value

    operands = types.array_of(operand)\tag "operands"

    split_ntuples(3, 2, "operands") * t({
      "exp"
      types.any\tag "left"
      operands: operands
    }) % (val, state) ->
      Line(
        node state.left
        unpack state.operands
      )
  
  -- only support on name, value right now
  assign: t({
    "assign"
    types.shape {
      match_node("ref")\tag "name"
    }
    types.shape {
      types.any\tag "value"
    }
  }) % (val, state) ->
    Line node(state.name), " = ", node state.value

  chain: do
    call_node = t({
      "call"
      types.array_of(types.any / node)\tag "args"
    }) % (val, state) ->
      args = { "(" }
      for idx, arg in ipairs state.args
        table.insert args, ", " unless idx == 1
        table.insert args, arg

      table.insert args, ")"

      Line unpack args

    call_node = call_node\describe '{ "call" } node'

    dot_node = t({
      "dot"
      types.string\tag "field"
    }) % (val, state) ->
      ".#{state.field}"

    dot_node = dot_node\describe '{ "dot" } node'

    index_node = t({
      "index"
      (types.any / node)\tag "field_expression"
    }) % (val, state) ->
      Line "[", state.field_expression, "]"

    index_node = index_node\describe '{ "index" } node'

    t({
      "chain"
      (types.any / node)\tag "root"
    }, {
      extra_fields: types.map_of(
        types.number
        types.scope(call_node + dot_node + index_node)\tag "actions[]"
      )
    }) % (val, state) ->
      Line state.root, unpack state.actions or {}

  parens: t({
    "parens"
    (types.any / node)\tag "value"
  }) % (val, state) ->
    Line "(", state.value, ")"

  return: t({
    "return"
    t {
      "explist"
      (types.any / node)\tag "value"
    }
  }) % (val, state) ->
    Line "return ", state.value

  fndef: t({
    "fndef"
    types.array_of types.shape {
      types.string\tag "args[]"
    }
    types.table -- whitelist, unused
    types.string\tag "type"
    types.table\tag "block"
  }) % (val, state) ->
    args = {
      "function("
    }

    if state.args
      for idx, arg in ipairs state.args
        table.insert args, ", " unless idx == 1
        table.insert args, arg

    table.insert args, ") "

    table.insert args, Block "{", "}", state.block
    Line unpack args

}
