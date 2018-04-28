
# MoonScript -> JavaScript

This is a new transformer and compiler for MoonScript that targets JavaScript.
It is an experiment to test [tableshape](https://github.com/leafo/tableshape)
as a way to rewrite the MoonScript to Lua transformer. Using tableshape will
make it easier to develop new features and generate optimized code at the
expense of compiling slower compared to the hand written transformer MoonScript
currently uses. (Hopefully the performance penalty is not significant)

In the current MoonScript implementation, the transformer and compiler run at
the same time. State about the code, like what variables are declared, are
stored in the compiler. When the compiler compiles a line, it can set state for
the transfer to see on the next line it processes.

In this new approach, the compiler and transformer are completely separate
steps. The compiler is responsible for translating a subset of syntax nodes to
to the target language code with no state. The transformer will run completely
ahead of time and keep track of all state as it transforms the syntax tree.

This approach should help clean up some of the more problematic nodes in
MoonScript, like the "Run" node. The syntax tree will go back to a plain table
tree with no special instanced nodes that have compiler state in them.

## Why JavaScript

It's not clear if this project will result in a fully functional JavaScript
alternative. MoonScript has a lot of Lua semantics built into its syntax that
will not map well to JavaScript. It is not a goal of this project to change any
of MoonScript's syntax to be more compatible with JavaScript.

It will allow you to compile a subset of the MoonScript syntax to JavaScript,
giving you the opportunity to write shared code across browser and server.

Hopefully this can be used to write Lapis views that can be used in JavaScript.
