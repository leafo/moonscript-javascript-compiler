
import types from require "tableshape"
import Proxy, t from require "moonscript.javascript.util"

-- operates on statements
statements_value_visitor = (value_visitor) ->
  local statements, value
  statements_proxy = Proxy(-> statements)\describe "value visitor statements"
  value_proxy = Proxy(-> value)\describe "value visitor"

  value = types.one_of {
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

    t {
      "for"
      types.any
      types.shape {
        value_proxy
        value_proxy
        types.nil + value_proxy
      }
      statements_proxy
    }

    t {
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

    t {
      "while"
      value_proxy -- cond
      statements_proxy
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

  value = value_visitor * types.assert(value) + value

  statements = types.array_of types.one_of {
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

  statements


{:statements_value_visitor}
