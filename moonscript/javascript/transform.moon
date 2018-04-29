
import types from require "tableshape"
import Proxy, ArrayLastItemShape from require "moonscript.javascript.util"

-- debug value
TEN = {"number", 10}

match_node = (name) ->
  types.shape { name }, open: true

to_ref = types.one_of {
  types.string / (name) -> {"ref", name}
  types.shape {"ref"}, open: true
}

t = (tbl, ...) ->
  tbl[-1] = types.number + types.nil
  types.shape tbl, ...

local find_hoistable
find_hoistable_proxy = Proxy -> find_hoistable
find_hoistable = types.array_of(types.one_of {
  t {
    "assign"
    types.shape {
      t {
        "ref"
        types.string\tag "names[]"
      }
    }
    types.any
  }

  t {
    "if"
    types.any
    find_hoistable_proxy
  }, extra_fields: types.map_of types.number, types.one_of {
    t {
      "elseif"
      types.any -- cond
      find_hoistable_proxy
    }

    t {
      "else"
      find_hoistable_proxy
    }
  }

  t {
    "for"
    types.string\tag "names[]"
    types.any
    find_hoistable_proxy
  }

  types.any
})

hoist_declares = find_hoistable % (val, state) ->
  if state != true and next state
    {
      {"declare", state.names}
      unpack val
    }
  else
    val


local implicit_return
implicit_return_proxy = Proxy -> implicit_return
implicit_return = ArrayLastItemShape types.one_of {
  -- things that can't be implicitly returned
  types.shape {
    types.one_of {
      "return", "assign", "declare", "for"
    }
  }, open: true

  -- enter bodies of if statements
  t {
    "if"
    types.any
    implicit_return_proxy
  }, extra_fields: types.map_of types.number, types.one_of {
    t {
      "elseif"
      types.any -- cond
      implicit_return_proxy
    }

    t {
      "else"
      implicit_return_proxy
    }
  }

  types.any / (val) -> { "return", { "explist", val } }
}

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

tree = types.array_of(transform_statement) * implicit_return * hoist_declares

{:tree}

