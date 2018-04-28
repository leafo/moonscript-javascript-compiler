
import types, BaseType from require "tableshape"

class Proxy extends BaseType
  new: (@fn) =>

  _transform: (...) =>
    assert(@.fn!, "proxy missing transformer")\_transform ...

  _describe: (...) =>
    assert(@.fn!, "proxy missing transformer")\_describe ...

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


{:split_ntuples, :Proxy}
