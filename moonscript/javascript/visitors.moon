
import types from require "tableshape"
import Proxy, t from require "moonscript.javascript.util"

-- operates on statements
statements_value_visitor = (value_shape) ->
  local statements, value
  statements_proxy = Proxy(-> statements)\describe "value visitor statements"
  value_proxy = Proxy(-> value)\describe "value visitor"

  value = value_shape + types.one_of {
    t {
      "fndef"
      array_of types.one_of {
        types.shape { types.any } -- argument name
        types.shape { types.any, value_proxy } -- argument name & default value
      }
    }

    t {
      types.one_of { "minus", "parens", "not" }
      value_proxy
    }

    t {
      "exp"
    }, extra_fields: types.map_of types.number, types.string + value_proxy

    -- TODO: comprehension

    types.any
  }

  statements = types.array_of types.one_of {
    t {
      "assign"
      types.any
      types.array_of(statements_proxy)
    }

    t {
      "if"
      value
      types.array_of(statements_proxy)
    }, extra_fields: types.map_of types.number, types.one_of {
      t {
        "elseif"
        value
        types.array_of(statements_proxy)
      }

      t {
        "else"
        types.array_of(statements_proxy)
      }
    }

    t {
      "for"
      types.any
      types.shape {
        value
        value
        types.nil + value
      }
      statements_proxy
    }

    t {
      "foreach"
      types.array_of(types.any)

      types.shape {
        types.shape {
          "unpack"
          value
        }
      }

      statements_proxy
    }


    t {
      "while"
      value -- cond
      statements_proxy
    }

    t {
      "chain"
      value
    }, extra_fields: types.map_of(
      types.number
      types.one_of {
        types.shape {"index", value}
        types.shape {"call", types.array_of(value)}
        types.any
      }
    )

    t {
      "return"
      types.literal("") + types.shape { "explist" }, {
        extra_fields: types.map_of(
          types.number
          value
        )
      }
    }

    t {
      "table"
      types.array_of types.one_of {
        -- array items
        types.array_of value, length: types.literal(1)

        -- object items
        types.shape {
          types.one_of {
            types.shape { "key_literal" }, open: true
            value
          }
          value
        }
      }
    }

    value
  }


{:statements_value_visitor}
