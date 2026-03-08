# Cuis-Smalltalk-StdIO

Stdin, stdout, stderror, and a simple REPL (Read Eval Print Loop)

Refactored for Cuis 7.6

````Smalltalk
  Feature require: #'StdIO'.
  [(StdIOReadEvalPrint newWithDefaults) readEvalPrint] fork. "Blocks image unless running on supported VM on Unix like process"
````
## REPL Features
Inputs are valid Smalltalk, except for the character marking end of input. No other special characters or keywords are parsed. Access instance with messages to ''self''.

````Smalltalk
  self help "Shows detailed help message"
  self commands "Shows a list of commands"
  self previousOutput. self outputAt: aNumber "Retrieve an answer that can be interacted with as a Smalltalk object"
  self runPreviousInput. self runInputAt: aNumber "Rerun a previous input"
````
### REPL Session Manager
The session manager can be accessed with "self sn". Use session manager to access inputs and outputs. Declare and reuse shared variables. And save the REPL session to a text file.

````Smalltalk
  self sn help
  self sn commands
````

### Variables
Temporary variables can be declared using the usual method. These are scoped only to that input. 

Shared variables can be declared using messages to the Session Manager, under the 'binding' category. These are accessible within the session. Shared variable names must be a #Symbol.

### Object Reuse
Outputs are saved and retrieved within the REPL session as Smalltalk objects.

Block Closures can be created and saved as either output or shared variable and reused within the REPL session.

````
1 >  [:a :b | a * b]! "Save a block closure to the output"
...
2 >  "Alias of self sn previousOutput"
     (self previousOutput) value: 3 value: 5! 
...
3 >  self sn assignTo: #aBlock value: [:a :b | a * b]! "Save a block closure to a shared variable"
...
4 >  (self sn valueOf: #aBlock) value: 3 value: 5!
````
