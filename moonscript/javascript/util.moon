
import types, BaseType, FailedTransform from require "tableshape"

class Proxy extends BaseType
  new: (@fn, @opts) =>

  _transform: (...) =>
    assert(@.fn!, "proxy missing transformer")\_transform ...

  _describe: (...) =>
    assert(@.fn!, "proxy missing transformer")\_describe ...

class ArrayLastItemShape extends BaseType
  new: (@last_item_shape, @opts) =>
    super!

  _transform: (value, state) =>
    if type(value) != "table"
      return FailedTransform, "expected table for last item check"

    size = #value
    if size == 0
      return value, state

    last_item = value[size]
    new_last_item, state_or_err = @.last_item_shape\_transform last_item, state

    if new_last_item == FailedTransform
      return FailedTransform, "last item: #{state_or_err}"

    if new_last_item == last_item
      value, state
    else
      out = {}
      for k,v in pairs value
        out[k] = if k == size
          new_last_item
        else
          v

      out, state

  _describe: =>
    "Last item<#{@last_item_shape\_describe!}>"

reserved_words = types.one_of({
  "case", "catch", "class", "const", "continue", "debugger", "default",
  "delete", "do", "else", "export", "extends", "finally", "for",
  "function", "if", "import", "in", "instanceof", "new", "return",
  "super", "switch", "this", "throw", "try", "typeof", "var", "void",
  "while", "with", "yield",

  "enum", "implements", "interface", "let", "package", "private", "protected",
  "public", "static", "await",
})

-- splits up the remaining numeric fields of a table into groups of size,
-- stored into rest. See spec/util_spec for examples
split_ntuples = (start=1, size=1, rest_name="rest") ->
  types.table / (t) ->
    out = {}
    for k,v in pairs t
      continue if type(k) == "number" and k >= start
      out[k] = v

    rest = {}
    for i=start,#t,size
      if size == 1
        table.insert rest, t[i]
      else
        table.insert rest, [t[k] for k=i,i+(size - 1)]

    out[rest_name] = rest
    out


STRICT = true
t = (tbl, ...) ->
  tbl[-1] = types.number + types.nil
  shape = types.shape tbl, ...

  if STRICT
    node_type_pattern = assert tbl[1], "missing node type pattern for t()"
    before_check = types.shape {
      node_type_pattern
    }, open: true

    fail = (node) ->
      expecting_type = switch type(node_type_pattern)
        when "table"
          node_type_pattern\_describe!
        when "string"
          node_type_pattern

      node_dump = require("moonscript.dump").tree { node }
      -- node_dump = require("moon").dump node
      error "Failed to get t(#{expecting_type}), got:\n#{node_dump}"

    before_check * (shape + types.any / fail)
  else
    shape

{:split_ntuples, :Proxy, :ArrayLastItemShape, :t}
