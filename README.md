
# MoonScript -> JavaScript

This is a new transformer and compiler for MoonScript that targets JavaScript.
It is an experiment to test [tablshape]() as a way to rewrite the MoonScript
transformer. It will make it easier to develop new features and generate
optimized code.

In the current MoonScript implementation, the transformer and compiler run at
the same time. State about the code, like what variables are declared, are
stored in the compiler. The transformer can be aware of state after the compiler
has compiled a line.

In this new approach, the compiler does a very simple transformation, with no
knowledge of the state of the code. The transformer will run completely ahead
of time and keep track of all state as it transforms the syntax tree.

This approach should help clean up some of the more problematic nodes in
MoonScript, like the "Run" node. The syntax tree will go back to a plain table
tree with no special instanced nodes that have compiler state in them.
