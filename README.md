# Usage

`$ ruby cy.rb -f foo.cy` <br> run `foo.cy` as a cy program

`$ ruby cy.rb -i foo.cy` <br> run `foo.cy`, and print the stack after each line

`$ ruby cy.rb -r foo.cy` <br> run `foo.cy`, enter REPL mode with the resulting stack/namespace.

`$ ruby cy.rb -r` <br> cy REPL mode

`$ruby cy.rb -m foo.cy` <br> output the markdown for posting the contents of `foo.cy` as an answer on CodeGolf.SE


# Doc

## Operators
- `+` add
- `-` subtract
- `*` multiply
- `/` divide ("true")
- `!!` subscript
- `>` `<` `>=` `<=` comparison

## Variables
A variable is initialized with an `=` sign before it. This will pop a value off of the stack and assign it to the variable. E.g., `10 =x` will assign `x` to 10. The value of a variable can be retrieved with a `$` sign. E.g., if `x` is 10, `$x` will push `10` to the stack. A reference to a variable is denoted by `.`, as in `.x`. This is used for augmented assignment and the like.

### Quick Reference

- `=foo` assignment
- `$foo` read
- `.foo` reference
- `.foo ++` increment
- `.foo --` decrement
- `.foo 2 +=` increase
- `.foo 2 -=` decrease
- `.foo 2 *=` multiply
- `.foo 2 /=` divide


## Blocks and Functions
A block is surrounded by `{ }`. This denotes a set of instructions. **A block of code is an object containing a set of instructions, and as such these instructions are not immediately executed**. Blocks are passed as arguments to constructions such as the `while` loop, `if` statement, etc. 

Since a block is simply a type of object, blocks can of course be pushed and popped on the stack, stored in containers, or assigned to a variable. The latter is how a function can be defined: store a block in a variable. There are two ways to call a block. The first is the "method" approach; if a block is stored in a variable, simply writing the name of the variable (important: no `$` should precede it) will call it. Alternatively, the `!` operator will invoke the block at the top of the stack.

Example:


	>> { 1 + 2 * } =f # f(x) = 2(x+1)
	=> []
	
	>> 3 f
	=> [8]
	
	>> $f
	=> [8, { 1 + 2 * }]
	
	>> !
	=> [18]

