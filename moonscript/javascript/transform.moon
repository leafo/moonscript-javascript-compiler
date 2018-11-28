import types from require "tableshape"
import Proxy, ArrayLastItemShape, t from require "moonscript.javascript.util"
import statements_value_visitor from require "moonscript.javascript.visitors"

-- an inherited scope
class Scope extends types.scope
  create_scope_state: (existing) =>
    setmetatable {}, __index: existing

-- debug value
TEN = {"number", 10}

debug = (str, node) ->
  node % (val, state) ->
    print str, require("moon").dump {
      val
      state
    }
    val

match_node = (name) ->
  types.shape { name }, open: true

to_ref = types.one_of {
  types.string / (name) -> {"ref", name}
  types.shape {"ref"}, open: true
}

unused_name = (prefix, state) ->
  declared_names = if state and state.declared_names
    {name, true for name in *state.declared_names}

  name = "_#{prefix}"
  k = 1
  while declared_names and declared_names[name]
    name = "_#{prefix}_#{k}"
    k += 1

  name

one_of_state = (field) ->
  types.custom (val, state) ->
    if list = state and state[field]
      for item in *list
        if val == item
          return true

    nil, "not in state"



local *

transform_statement_proxy = Proxy(-> transform_statement)\describe "transform_statement"
transform_value_proxy = Proxy(-> transform_value)\describe "transform_value"

find_hoistable_proxy = Proxy(-> find_hoistable)\describe "find_hoistable"


-- converts all regular "this" to the bound this 
bind_this_visitor = statements_value_visitor {
  value_visitor: types.one_of {
    types.shape({"ref", "this"}, open: true) % (v, state) ->
      assert state.bind_this, "missing state for bind this"
      { [-1]: v[-1], "ref", state.bind_this }

    -- far arrow in same scope get automatically converted and visited
    types.shape({
      "fndef"
      [4]: "fat"
    }, open: true) / (node) ->
      copy = {k,v for k,v in pairs node}
      copy[4] = "slim"
      copy
  }

  -- stop on slim arrows becuase they create new scope
  value_halt: types.shape {
    "fndef"
    [4]: "slim"
  }, open: true
}

-- prevents grabbing names already pulled or declared
record_name = types.one_of {
  one_of_state "declared_names"
  one_of_state "names"
  types.string\tag "names[]"
}

find_hoistable_statements = types.array_of(find_hoistable_proxy)

find_hoistable = types.one_of {
  t {
    "assign"
    types.shape {
      t {
        "ref"
        record_name
      }
    }
    types.array_of(find_hoistable_proxy)
  }

  -- declares can be removed
  t({
    "declare"
    types.array_of types.one_of {
      one_of_state("declared_names") / nil
      one_of_state("names") / nil
      types.string\tag "declared_names[]"
    }
  }) * types.one_of {
    types.shape({ "declare", types.shape {} }) / nil
    types.any
  }

  t {
    "declare_with_shadows"
    types.array_of(types.string\tag "declared_names[]")
  }

  t {
    "if"
    find_hoistable_proxy -- cond
    find_hoistable_statements
  }, extra_fields: types.map_of types.number, types.one_of {
    t {
      "elseif"
      find_hoistable_proxy -- cond
      find_hoistable_statements
    }

    t {
      "else"
      find_hoistable_statements
    }
  }

  t {
    "for"
    record_name
    types.shape {
      find_hoistable_proxy
      find_hoistable_proxy
      types.nil + find_hoistable_proxy
    }
    find_hoistable_statements
  }

  t {
    "foreach"
    types.array_of(record_name)

    types.shape {
      types.shape {
        "unpack"
        find_hoistable_proxy
      }
    }

    find_hoistable_statements
  }

  t {
    "while"
    find_hoistable_proxy -- cond
    find_hoistable_statements
  }

  t {
    "chain"
    find_hoistable_proxy
  }, extra_fields: types.map_of(
    types.number
    types.one_of {
      types.shape {"index", find_hoistable_proxy}
      types.shape {"call", types.array_of(find_hoistable_proxy)}
      types.any
    }
  )

  t {
    "return"
    types.literal("") + types.shape { "explist" }, {
      extra_fields: types.map_of(
        types.number
        find_hoistable_proxy
      )
    }
  }

  -- TODO: this is duplicated on transform_table
  t {
    "table"
    types.array_of types.one_of {
      -- array items
      types.array_of find_hoistable_proxy, length: types.literal(1)

      -- object items
      types.shape {
        types.one_of {
          types.shape { "key_literal" }, open: true
          find_hoistable_proxy
        }
        find_hoistable_proxy
      }

    }
  }

  -- find bound this
  types.shape({
    "fndef"
    [4]: "fat"
  }, open: true) * t {
    "fndef"
    types.any
    types.any
    types.literal("fat")\tag(
      (s) ->
        unless s.bind_this
          s.bind_this = unused_name("this", state)
          names = {}
          if s.names
            for name in *s.names
              table.insert names, name

          table.insert names, s.bind_this
          s.names = names

    ) / "slim"
    bind_this_visitor
  }

  types.any
}

-- get the names already declared at the top of the block
existing_declare = types.shape {
  t({
    "declare"
    types.array_of(types.string\tag "names[]")
  })
}, open: true

hoist_declares = Scope types.array_of(find_hoistable) % (val, state) ->
  names = state and state.names

  if state and state.bind_this
    if names
      names = {state.bind_this, unpack names}
    else
      names = {state.bind_this}

  unless names and next names
    -- nothing hoisted
    return val

  ed = existing_declare(val)

  k, names = if ed
    for name in *names
      table.insert ed.names, name

    2, ed.names
  else
    1, names

  out = {
    {"declare", names}
    if state.bind_this
      {"assign", {{"ref", state.bind_this}}, {{"ref", "this"}}}
  }

  for i=k,#val
    table.insert out, val[i]

  out

transform_last_expression = (fn) ->
  local transform_last
  transform_last_proxy = Proxy(-> transform_last)\describe "transform_last"

  transform_last = ArrayLastItemShape types.one_of {
    -- things that can't be implicitly returned
    types.shape {
      types.one_of {
        "return", "assign", "declare", "for", "foreach", "while"
      }
    }, open: true

    -- enter bodies of if statements
    t {
      "if"
      types.any
      transform_last_proxy
    }, extra_fields: types.map_of types.number, types.one_of {
      t {
        "elseif"
        types.any -- cond
        transform_last_proxy
      }

      t {
        "else"
        transform_last_proxy
      }
    }

    types.any / fn
  }

  transform_last

implicit_return = transform_last_expression (val) -> { "return", { "explist", val } }

transform_foreach = Scope t({
  "foreach"
  types.array_of(types.string * to_ref)\tag "loop_vars"
  types.shape {
    types.shape {
      "unpack"
      types.any\tag "list_expression"
    }
  }
  types.any\tag "block"
}) % (value, state) ->
  index_name = unused_name("i", state)

  item_var = unpack state.loop_vars
  length = {"chain", state.list_expression, {"dot", "length"}}
  item_val = {"chain", state.list_expression, {"index", {"ref", index_name}}}

  -- TODO: extract length calculation into comma exp done beforehand
  {
    "for"
    index_name
    {
      {"number", 0}
      {"exp", length, "-", {"number", "1"}}
    }
    {
      {"declare", {index_name}}
      {"assign", {item_var}, { item_val }}
      unpack state.block
    }
    [-1]: value[-1]
  }

transform_for = t {
  "for"
  types.any -- loop variable
  types.shape {
    transform_value_proxy
    transform_value_proxy
    types.nil + transform_value_proxy
  }
  types.array_of(transform_statement_proxy)
}

transform_chain = t {
  "chain"
  transform_value_proxy -- root
}, extra_fields: types.map_of(
  types.number
  types.one_of {
    types.shape {"index", transform_value_proxy}
    types.shape {"call", types.array_of(transform_value_proxy)}
    types.any
  }
)

transform_assign = t {
  "assign"
  types.any -- names
  types.array_of(transform_value_proxy)
}

-- TODO: refactor this into visitor constructors to avoid duplication
transform_table = t {
  "table"
  types.array_of types.one_of {
    -- array items
    types.array_of transform_value_proxy, length: types.literal(1)

    -- object items
    types.shape {
      types.one_of {
        types.shape { "key_literal" }, open: true
        transform_value_proxy
      }
      transform_value_proxy
    }
  }
}

transform_if = t {
  "if"
  transform_value_proxy
  types.array_of(transform_statement_proxy)
}, extra_fields: types.map_of types.number, types.one_of {
  t {
    "elseif"
    transform_value_proxy
    types.array_of(transform_statement_proxy)
  }

  t {
    "else"
    types.array_of(transform_statement_proxy)
  }
}

transform_fndef = Scope t {
  "fndef"

  -- args
  types.array_of types.shape {
    types.string\tag "declared_names[]"
  }

  types.any -- whitelist
  types.string -- type
  implicit_return * hoist_declares * Scope(types.array_of(transform_statement_proxy)) * hoist_declares
}

transform_return = t {
  "return"
  types.one_of {
    ""
    types.shape {
      "explist"
    }, extra_fields: types.map_of types.number, transform_value_proxy
  }
}

transform_comprehension = Scope t({
  "comprehension"
  types.any\tag "value_expression"
  -- todo: support nested loops
  types.array_of types.one_of({
    types.shape {
      "foreach"
      types.any
      -- for some reason the unpack syntax is inconsistent here
      types.any / (v) -> {v}
    }
    types.any -- other loops are fine?
  })\tag "loops[]"
}) % (node, state) ->
  accum_var = to_ref\transform unused_name "accum", state

  current = {"chain", accum_var,
    {"dot", "push"}
    {"call", {
      state.value_expression
    }}
  }

  for idx=#state.loops,1,-1
    loop = { unpack state.loops[idx] }
    table.insert loop, {
      current
    }
    current = loop

  fn = {
    "fndef", {}, {}, "slim", {
    {"assign", { accum_var }, { {"array"} }}
    current
    {"return", {"explist", accum_var}}
  }}

  {
    [-1]: node[-1]
    "chain"
    {"parens", fn}
    {"call", {}}
  }

transform_accumulated_loop = Scope t({
  types.one_of {
    "foreach"
    "for"
    "while"
  }
}, open: true) % (node, state) ->
  accum_var = to_ref\transform unused_name "accum", state

  -- TODO: expensive to build shape on transform, store accum in state?
  accumulate_body = transform_last_expression (v) ->
    {"chain", accum_var,
      {"dot", "push"}
      {"call", {
        v
      }}
    }

  accumulate_loop = types.one_of {
    types.shape {
      [-1]: types.any
      types.one_of { "foreach", "for" }
      types.any
      types.any
      types.any * accumulate_body
    }
    types.shape {
      [-1]: types.any
      "while"
      types.any
      types.any * accumulate_body
    }
  }

  fn = {
    "fndef", {}, {}, "slim", {
    {"assign", { accum_var }, { {"array"} }}
    assert accumulate_loop\transform node
    {"return", {"explist", accum_var}}
  }}

  {
    [-1]: node[-1]
    "chain"
    {"parens", fn}
    {"call", {}}
  }

transform_class = t({
  "class"
  types.any -- name
  types.any -- parent
  types.any -- body
}) % (node, state) ->
  {
    "fndef"
    {}
    { name: node[2] }
    "slim"
    {}
  }

transform_value = types.one_of {
  transform_chain
  transform_table
  transform_fndef
  transform_class
  transform_comprehension * transform_value_proxy
  transform_accumulated_loop * transform_value_proxy

  types.all_of {
    t({
      "if"
    }, open: true) % (node) ->
      fn = {"fndef", {}, {}, "slim", {
        node
      }}

      {
        [-1]: node[-1]
        "chain"
        {"parens", fn}
        {"call", {}}
      }

    transform_value_proxy
  }

  t {
    types.one_of { "parens", "not", "minus" }
    transform_value_proxy
  }

  t({"string"}, open: true) % (node) ->
    if #node > 3
      out = {[-1]: node[-1], "exp"}
      convert_chunk_expression = types.one_of {
        types.string / (v) -> {[-1]: node[-1], "string", node[2], v}
        t({"interpolate", types.any}) / (v) -> v[2]
      }
      for idx=3,#node
        val = convert_chunk_expression\transform node[idx]
        if idx > 3
          table.insert out, "+"
        table.insert out, val
      out
    elseif types.shape({ [-1]: types.any, "string", types.any, t({"interpolate"}, open: true) }) node
      {"exp", {"string", '"', ""}, "+", node[3][2]}
    else
      node

  t {
    "exp"
  }, extra_fields: types.map_of types.number, types.string + transform_value_proxy

  types.any
}

transform_statement = types.one_of {
  transform_foreach * transform_statement_proxy
  transform_for
  transform_assign
  transform_if
  transform_return

  t {
    "declare"
    types.array_of(
      one_of_state("declared_names") + types.string\tag "declared_names[]"
    )
  }

  {
    "declare_with_shadows"
    types.array_of(
      one_of_state("declared_names") + types.string\tag "declared_names[]"
    )
  }

  types.shape({
    types.one_of {
      "ref", "not", "parens", "minus", "string", "number", "fndef", "table",
      "chain"
    }
  }, open: true) * transform_value

  types.any
}

local transform_two
transform_two_proxy = Proxy(-> transform_two)\describe "transform_two"
transform_two = statements_value_visitor {
  value_visitor: types.one_of {
    -- transform_fndef --edited version

    Scope t {
      "fndef"

      -- args
      types.array_of types.shape {
        types.string\tag "declared_names[]"
      }

      types.any -- whitelist
      types.string -- type
      implicit_return * hoist_declares * Scope(transform_two_proxy) * hoist_declares
    }

    transform_class
    transform_comprehension
    transform_accumulated_loop

    t({
      "if"
    }, open: true) % (node) ->
      fn = {"fndef", {}, {}, "slim", {
        node
      }}

      {
        [-1]: node[-1]
        "chain"
        {"parens", fn}
        {"call", {}}
      }

    t({"string"}, open: true) % (node) ->
      if #node > 3
        out = {[-1]: node[-1], "exp"}
        convert_chunk_expression = types.one_of {
          types.string / (v) -> {[-1]: node[-1], "string", node[2], v}
          t({"interpolate", types.any}) / (v) -> v[2]
        }
        for idx=3,#node
          val = convert_chunk_expression\transform node[idx]
          if idx > 3
            table.insert out, "+"
          table.insert out, val
        out
      elseif types.shape({ [-1]: types.any, "string", types.any, t({"interpolate"}, open: true) }) node
        {"exp", {"string", '"', ""}, "+", node[3][2]}
      else
        node

  }

  statement_visitor: types.one_of {
    transform_foreach

    t {
      "declare"
      types.array_of(
        one_of_state("declared_names") + types.string\tag "declared_names[]"
      )
    }

    {
      "declare_with_shadows"
      types.array_of(
        one_of_state("declared_names") + types.string\tag "declared_names[]"
      )
    }
  }
}


tree = types.all_of {
  implicit_return
  hoist_declares
  Scope(types.array_of(transform_statement))
  hoist_declares
}

{:tree}

