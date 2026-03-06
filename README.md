# Cuis-Smalltalk-StdIO

Stdin, stdout, stderror, and a simple REPL (Read Eval Print Loop)

Refactored for Cuis 7.6

````Smalltalk
  Feature require: #'StdIO'.
  [(StdIOReadEvalPrint newWithDefaults) readEvalPrint] fork. "Blocks image unless running on supported VM on Unix like process"
````
## REPL Features
REPL instance responds to #self.

````Smalltalk
  self help "Shows a help message"
  self previousOutput. self outputAt: aNumber "Retrieve an answer that can be interacted with as a Smalltalk object"
  self previousInput. self inputAt: aNumber "Retrieve an input as string"
  self saveContents. self saveContentsTo: aString asFileEntry "Save current REPL session input and output strings to file"
````
