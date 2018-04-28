
-- this compiler is different than moonscript, it operatrs on transformed nodes
-- only, doing simple compile

local Line, Block

node = (n) ->
  node_type = assert n[1], "node does not have node type"
  compiler = require("moonscript.javascript.compilers")[node_type]

  unless compiler
    error "no compiler for node type #{node_type}"

  out, err = compiler\transform n

  unless out
    error "failed compiling #{node_type}: #{err}"

  out

class Block
  indentation_char: "  "

  header: ""
  footer: ""
  join: "\n"

  new: (@header, @footer, lines) =>
    @lines = {}

    if lines
      for line in *lines
        @append_statement line

  -- compile the node and append it
  append_statement: (statement) =>
    line = node statement

    unless line
      return

    if type(line) == "string"
      line = Line line

    table.insert @lines, line

  -- join all the lines at the correct indentation, with header and footer if
  -- necessary
  render: (indent=0) =>
    prefix = @indentation_char\rep indent
    suffix = ";"

    out = { }

    if @header and @header != ""
      table.insert out, @header

    for line in *@lines
      rendered_line = "#{prefix}#{line\render indent}"
      unless rendered_line\match "}$"
        rendered_line ..= suffix

      table.insert out, rendered_line

    if @footer and @footer != ""
      table.insert out, @indentation_char\rep(indent - 1) ..@footer

    table.concat out, @join

class Line
  new: (...) =>
    args = select "#", ...
    @chunks = {}
    for i=1,args
      arg = select i, ...
      if arg != nil
        if type(arg) == "table" and arg.__class == Line
          for chunk in *arg.chunks
            table.insert @chunks, chunk
        else
          table.insert @chunks, arg

  render: (indentation=0) =>
    out = for chunk in *@chunks
      switch type(chunk)
        when "string"
          chunk
        when "table"
          if chunk.render
            chunk\render indentation + 1
          else
            error "unknown table passed to render"

    table.concat out


{:Block, :Line, :node}
