
import types, BaseType from require "tableshape"
import Line, Block, node from require "moonscript.javascript.compile"

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
  }) % (value, state) ->
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
  
  exp: t({
    "exp"
    types.any\tag "left"
    types.string\tag "operator"
    types.any\tag "right"
  }) % (val, state) ->
    Line node(state.left), " #{state.operator} ", node(state.right)
  
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

    t({
      "chain"
      types.any\tag "root"
    }, {
      extra_fields: types.map_of(
        types.number
        types.scope(call_node + dot_node)\tag "actions[]"
      )
    }) % (val, state) ->
      Line node(state.root), unpack state.actions or {}


}
