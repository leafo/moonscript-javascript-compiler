
import types from require "tableshape"
import Proxy, t from require "moonscript.javascript.util"

-- operates on statements
statements_value_visitor = (opts={}) ->
  {:value_visitor, :statement_visitor, :value_halt} = opts

  local statements, value
  statements_proxy = Proxy(-> statements)\describe "value visitor statements"
  value_proxy = Proxy(-> value)\describe "value visitor"

  if_visitor = t {
    "if"
    value_proxy
    statements_proxy
  }, extra_fields: types.map_of types.number, types.one_of {
    t {
      "elseif"
      value_proxy
      statements_proxy
    }

    t {
      "else"
      statements_proxy
    }
  }

  for_visitor = t {
    "for"
    types.any
    types.shape {
      value_proxy
      value_proxy
      types.nil + value_proxy
    }
    statements_proxy
  }

  foreach_visitor = t {
    "foreach"
    types.array_of(types.any)

    types.shape {
      types.shape {
        "unpack"
        value_proxy
      }
    }

    statements_proxy
  }

  while_visitor = t {
    "while"
    value_proxy -- cond
    statements_proxy
  }

  value = types.one_of {
    if_visitor
    for_visitor
    foreach_visitor
    while_visitor

    t {
      "fndef"
      types.array_of types.one_of {
        types.shape { types.any } -- argument name
        types.shape { types.any, value_proxy } -- argument name & default value
      }

      types.any -- whitelist
      types.string -- type
      statements_proxy
    }

    t {
      types.one_of { "minus", "parens", "not" }
      value_proxy
    }

    t {
      "exp"
    }, extra_fields: types.map_of types.number, types.string + value_proxy

    t {
      "comprehension"
      value_proxy
      types.array_of types.one_of {
        types.shape {
          "foreach"
          types.any
          types.one_of {
            types.shape {
              "unpack"
              value_proxy
            }
            value_proxy
          }
        }

      }
    }


    t {
      "table"
      types.array_of types.one_of {
        -- array items
        types.array_of value_proxy, length: types.literal(1)

        -- object items
        types.shape {
          types.one_of {
            types.shape { "key_literal" }, open: true
            value_proxy
          }
          value_proxy
        }
      }
    }

    t {
      "chain"
      value_proxy
    }, extra_fields: types.map_of(
      types.number
      types.one_of {
        types.shape {"index", value_proxy}
        types.shape {"call", types.array_of(value_proxy)}
        types.any
      }
    )

    types.any
  }

  if value_visitor
    value = value_visitor * types.assert(value) + value

  if value_halt
    value = value_halt + value

  statement = types.one_of {
    if_visitor
    for_visitor
    foreach_visitor
    while_visitor

    t {
      "assign"
      types.any
      types.array_of value
    }

    t {
      "return"
      types.literal("") + types.shape { "explist" }, {
        extra_fields: types.map_of(
          types.number
          value
        )
      }
    }

    value
  }

  if statement_visitor
    statement = statement_visitor * types.assert(statement) + statement

  statements = types.array_of statement
  statements, value

{:statements_value_visitor}
