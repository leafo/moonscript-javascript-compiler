
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
    else_node = types.scope t({
      "else"
      types.table\tag "block"
    }), tag: "else"

    else_if_node = types.scope t({
      "elseif"
      types.any\tag "cond"
      types.table\tag "block"
    }), tag: "elseif[]"

    t({
      "if"
      types.any\tag "cond"
      types.table\tag "block"
    }, extra_fields: types.map_of(
      types.number
      else_if_node + else_node
    )) % (val, state) ->
      args = {
        "if ("
        node state.cond
        ") "
        Block "{", "}", state.block
      }

      if state.elseif
        for child_state in *state.elseif
          table.insert args,
            Block(
              " else if (#{node child_state.cond}) {"
              "}"
              child_state.block
            )

      if state.else
        table.insert args,
          Block " else {", "}", state.else.block

      Line unpack args

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
    "#{node state.left} #{state.operator} #{node state.right}"
  
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
    "#{node state.name} = #{node state.value}"

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
