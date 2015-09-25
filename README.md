#bfukt
####*A silly little language that compiles into a sillier, little one*

Have you ever noticed that most the languages that compile to brainfuck dont 
have the same neat little heart that brainfuck does? They're either far too bf
still, or they are languages like C where the BF output looks nothing like
lovingly crafted brainfuck.

I have tried to design a language and compiler that can create neat little bf
code that looks like it could have been handwritten, but is still better than
simple macros.

##To Build the Compiler
Simply compile it in coffeescript, there is no additional assemblies and what 
not

##Usage
Have a look in the example page to see it embedded within a web page, basically
all you have to do is call `parse`, passing in a javascript object with a 
property `'lines'` that is an array of the lines of code.

##Apologies
It's a WIP, and I'm not too serious about it. As such the compiler isnt perfect,
and the error messages are not particularly usefule. Feel free to tell me about
any bugs you find, or better yet, fix them for me.

##The Language
The language is dynamically typed, although that said, there is only two types.
The two types are functions and variables, and they can be used interchangable 
(first class functions).

###Comments
A line that starts with a `#hash` is a comment

###Declaring a variable
Declaring a variable is simple, and all of the following are valid and do what
you would expect them to. Names are characters only, sorry, no underscores or 
numbers.

***
var j
var foo, bar

\# Declare foo, set to 5
var foo = 5

\# Declare a & b, they will both have the ASCII value of 'c'
var a, b = 'c'

\# Declare c, and set it's value to be the same as a
var c = a
***

### Arithmatic
This is where things get a little interesting. You may set a variable to have
the value of a literal, a character or another variable. If the variable is 
prefixed by an underscore, then that tells the compiler that its value may
be zero after the operation. This allows much smaller brainfuck code.

You may add, subtract and set values.

***
\# Set a to 5
a = 5

\# Add 5 to a
+a = 5

\# Subtract 5 from a
-a = 5

\# Set a to 'A'
a = 'A'

\# Set a to b, with b keeping its original value
a = b

\# Set a to b, leaving b at zero
a = _b

\# Add 5 to a and b
+a, +b = 5

\# Add c to a, subtract c from b and leave c at zero
+a, -b = _c
***
