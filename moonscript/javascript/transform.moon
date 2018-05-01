
import types from require "tableshape"
import Proxy, ArrayLastItemShape from require "moonscript.javascript.util"

-- an inherited scope
class Scope extends types.scope
  create_scope_state: (existing) =>
    setmetatable {}, __index: existing

-- debug value
TEN = {"number", 10}

debug = (str, node) ->
  node % (val, state) ->
    print str, require("moon").dump state
    val

match_node = (name) ->
  types.shape { name }, open: true

to_ref = types.one_of {
  types.string / (name) -> {"ref", name}
  types.shape {"ref"}, open: true
}

one_of_state = (field) ->
  types.custom (val, state) ->
    if list = state and state[field]
      for item in *list
        if val == item
          return true

    nil, "not in state"

t = (tbl, ...) ->
  tbl[-1] = types.number + types.nil
  types.shape tbl, ...

local find_hoistable
find_hoistable_proxy = Proxy(-> find_hoistable)\describe "find_hoistable"

-- prevents grabbing names already pulled or declared
record_name = types.one_of {
  one_of_state "declared_names"
  one_of_state "names"
  types.string\tag "names[]"
}

find_hoistable = types.array_of types.one_of {
  t {
    "assign"
    types.shape {
      t {
        "ref"
        record_name
      }
    }
    types.any
  }

  t {
    "declare"
    types.array_of(types.string\tag "declared_names[]")
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
    record_name
    types.any
    find_hoistable_proxy
  }

  types.any
}

hoist_declares = Scope find_hoistable % (val, state) ->
  if state and state.names
    {
      {"declare", state.names}
      unpack val
    }
  else
    val


local implicit_return
implicit_return_proxy = Proxy(-> implicit_return)\describe "implicit_return"
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

transform_foreach = Scope t({
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


transform_statement = types.one_of {
  transform_foreach

  t({
    "declare_with_shadows"
    types.any
  }) / (v) ->
    {"declare", v[2], [-1]: v[-1]}

  types.any
}

local statement_values
statement_values_proxy = Proxy(-> statement_values)\describe "statement_values"

local chain_values
chain_values_proxy = Proxy(-> chain_values)\describe "chain_values"

local table_values
table_values_proxy = Proxy(-> table_values)\describe "table_values"

local transform_value
transform_value_proxy = Proxy(-> transform_value)\describe "transform_value"

transform_fndef = Scope t {
  "fndef"

  -- args
  types.array_of types.shape {
    types.string\tag "declared_names[]"
  }

  types.any -- whitelist
  types.string -- type
  hoist_declares * types.array_of(statement_values_proxy) * implicit_return
}

transform_value = (types.one_of {
  chain_values_proxy
  table_values_proxy

  t {
    types.one_of { "parens", "not", "minus" }
    transform_value_proxy
  }

  t {
    "exp"
  }, extra_fields: types.map_of types.number, types.string + transform_value_proxy

  transform_fndef

  types.any
}) / (value) ->
  -- print "got value:"
  -- require("moon").p value
  -- print ""

  value

chain_values = t {
  "chain"
  transform_value -- root
}, extra_fields: types.map_of(
  types.number
  types.one_of {
    types.shape {"index", transform_value}
    types.shape {"call", types.array_of(transform_value)}
    types.any
  }
)

assign_values = t {
  "assign"
  types.any -- names
  types.array_of(transform_value)
}

table_values = t {
  "table"
  types.array_of types.one_of {
    -- array items
    types.array_of transform_value, length: types.literal(1)

    -- object items
    types.shape {
      types.one_of {
        types.shape { "key_literal" }, open: true
        transform_value
      }
      transform_value
    }
  }
}

if_values = t {
  "if"
  transform_value
  types.array_of(statement_values_proxy)
}, extra_fields: types.map_of types.number, types.one_of {
  t {
    "elseif"
    transform_value
    types.array_of(statement_values_proxy)
  }

  t {
    "else"
    types.array_of(statement_values_proxy)
  }
}

for_values = t {
  "for"
  types.any -- loop variable
  types.shape {
    transform_value
    transform_value
    types.nil + transform_value
  }
  types.array_of(statement_values_proxy)
}

-- a value that can appear as a statement
statement_values = types.one_of {
  chain_values
  assign_values
  table_values
  if_values
  for_values

  t {
    "declare"
    types.array_of(types.string\tag "declared_names[]")
  }

  t {
    "return"
    types.shape {
      "explist"
    }, extra_fields: types.map_of(types.number, transform_value)
  }

  types.shape({
    types.one_of {
      "ref", "not", "parens", "minus", "string", "number", "fndef"
    }
  }, open: true) * transform_value

  types.any
}

tree = types.array_of(transform_statement) * hoist_declares * types.array_of(statement_values) * implicit_return

{:tree}

