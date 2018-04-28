
import types from require "tableshape"

-- debug value
TEN = {"number", 10}


to_ref = types.one_of {
  types.string / (name) -> {"ref", name}
  types.shape {"ref"}, open: true
}

t = (tbl, ...) ->
  tbl[-1] = types.number + types.nil
  types.shape tbl, ...

transform_foreach = types.scope t({
  "foreach"
  types.array_of(types.string * to_ref)\tag "loop_vars"
  types.shape {
    types.shape {
      "unpack"
      types.any\tag "list_expression"
    }
  }
  types.array_of(types.any)\tag "block"
}) % (value, state) ->
  item_var = unpack state.loop_vars
  length = {"chain", state.list_expression, {"dot", "length"}}
  item_val = {"chain", state.list_expression, {"index", {"ref", "idx"}}}

  {
    "for"
    "idx"
    {
      {"number", 0}
      {"exp", length, "-", {"number", "1"}}
    }
    {
      {"assign", {item_var}, { item_val }}
      unpack state.block
    }
    [-1]: value[-1]
  }


transform_statement = transform_foreach + types.any

tree = types.array_of transform_statement

{:tree}

