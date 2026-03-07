# Cuis-Smalltalk-StdIO

Stdin, stdout, stderror, and a simple REPL (Read Eval Print Loop)

Refactored for Cuis 7.6

````Smalltalk
  Feature require: #'StdIO'.
  [(StdIOReadEvalPrint newWithDefaults) readEvalPrint] fork. "Blocks image unless running on supported VM on Unix like process"
````
## REPL Features
REPL instance can be accessed through self.

````Smalltalk
  self help "Shows a help message"
  self commands "Shows a list of commands"
  self previousOutput. self outputAt: aNumber "Retrieve an answer that can be interacted with as a Smalltalk object"
  self previousInput. self inputAt: aNumber "Retrieve an input as string"
  self runPreviousInput. self runInputAt: aNumber "Rerun a previous input"
  self saveContents. self saveContentsTo: aString asFileEntry "Save current REPL session input and output strings to file"
````
### Variables
Temporary variables can be declared using the usual method. These are scoped only to that input. 

Shared variables can be declared using messages under the 'binding' category. These are accessible within the session. Shared variable names must be a #Symbol.

### Object Reuse
Outputs are saved and retrieved within the REPL session as Smalltalk objects.

Block Closures can be created and saved as either output or shared variable and reused within the REPL session.

````
1 >  [:a :b | a * b]! "Save a block closure to the output"
...
2 >  (self previousOutput) value: 3 value: 5!
...
3 >  self assignTo: #aBlock value: [:a :b | a * b]! "Save a block closure to a shared variable"
...
4 >  (self valueOf: #aBlock) value: 3 value: 5!
````
