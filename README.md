# Postfix-Language


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


```ruby
=> []
:: 10 =x
=> []
:: $x
=> 10 [10]
```