# Usage

`$ ruby cy.rb -f foo.cy` <br> run `foo.cy` as a cy program

`$ ruby cy.rb -r foo.cy` <br> run `foo.cy`, enter REPL mode with the resulting stack/namespace.

`$ ruby cy.rb -r` <br> cy REPL mode

`$ ruby cy.rb -m foo.cy` <br> output the markdown for posting the contents of `foo.cy` as an answer on CodeGolf.SE

`$ ruby cy.rb -p` <br> implicit printing mode: all (non-block) values pushed to the stack will be printed automatically

`$ ruby cy.rb -e "some code"` <br> run code directly from command line


# Doc

## Operators
- `+` add
- `-` subtract
- `*` multiply
- `/` divide ("true")
- `!!` subscript
- `>`, `<`, `>=`, `<=`, `==` `!=` comparison

An ampersand `&` preceding an operator will leave its operands on the stack (dubbed [safe]guarding/shielding/safe mode).

A caret `^` preceding a method call will call the method in safe mode only if its containing block was called in safe mode.

Example: 
```ruby
>> {^+} =f
>> 1 2 3 f
:: [1 5]

>> &f
:: [1 5 6]
```

## Variables
A variable is initialized with an `=` sign before it. This will pop a value off of the stack and assign it to the variable. E.g., `10 =x` will assign `x` to 10. The value of a variable can be retrieved with a `$` sign. E.g., if `x` is 10, `$x` will push `10` to the stack. A reference to a variable is denoted by `.`, as in `.x`. This is used for augmented assignment and the like.

### Quick Reference

- `=foo` assignment
- `&=foo` assign, push value
- `$foo` read
- `.foo` reference
- `.foo ++` increment
- `.foo --` decrement
- `.foo &--` decrement and push old value
- `.foo --&` decrement and push new value
- `.foo 2 +=` add 2
- `.foo 2 &+=` add 2, push result
- `.foo 2 ^+=` add 2, push result IFF block was called with `&` guard.

## Blocks and Functions
A block is surrounded by `{ }`. This denotes a set of instructions. **A block of code is an object containing a set of instructions, and as such these instructions are not immediately executed**. Blocks are passed as arguments to constructions such as the `while` loop, `if` statement, etc. 

Since a block is simply a type of object, blocks can of course be pushed and popped on the stack, stored in containers, or assigned to a variable. The latter is how a function can be defined: store a block in a variable. There are two ways to call a block. The first is the "method" approach; if a block is stored in a variable, simply writing the name of the variable (important: no `$` should precede it) will call it. Alternatively, the `!` operator will invoke the block at the top of the stack.

Example:

```ruby
>> { 1 + 2 * } =f    # f(x) = 2(x+1)
=> []
	
>> 3 f
=> [8]
	
>> $f
=> [8, { 1 + 2 * }]

>> !
=> [18]
```

### Control Flow
Control flow operators take one or more blocks ("body") and often a "condition" (which may also be a block) that determines how the body is executed. By convention, the "condition" is before the "body". This is because the need for a variable condition is greater than the need for a variable body, so the condition can simply be popped off the stack. Unless otherwise specified, preceding the loop's name with an ampersand `&` will leave the condition on the stack. (e.g. `&each` will leave the iterable on the stack.) Common examples are the `if` statement, `while` loop, and `each` loop. 

#### List of Control Structures
Values are surrounded by parentheses `()` and arguments that expect blocks will be surrounded in braces `{}`.
- `(iterable) {body} each` <br> for each item of `iterable`, push it to the stack and invoke `body`
- `(condition) {body} while` <br> keep executing `body` while `condition` continues pushing a truthy value to the stack
- `{body} do` <br> execute `body` while the top of the stack (popped) is truthy
- `{body} &do` <br> execute `body` while the top of the stack is truthy
- `(condition) {tbody} {fbody} ?` <br> execute `tbody` if `condition`, else execute `fbody`
- `(condition) {body}` <br> execute `body` if `condition`.


# Examples

## Hello, World program
```ruby
"Hello, World!" print
```

## Infinite Fibonacci Sequence
```ruby
0 &print 1 &print {&+ &print} {true} while
```
Golfed:
```
0 1 {&+} &do # requires -p flag
```
