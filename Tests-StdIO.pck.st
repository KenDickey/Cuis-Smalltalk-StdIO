'From Cuis7.6 [latest update: #7777] on 7 March 2026 at 9:25:36 pm'!
'Description '!
!provides: 'Tests-StdIO' 1 4!
!requires: 'StdIO' 1 9 nil!
SystemOrganization addCategory: #'Tests-StdIO'!


!classDefinition: #StdIOReadEvalPrintTest category: #'Tests-StdIO'!
TestCase subclass: #StdIOReadEvalPrintTest
	instanceVariableNames: 'input output repl'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tests-StdIO'!
!classDefinition: 'StdIOReadEvalPrintTest class' category: #'Tests-StdIO'!
StdIOReadEvalPrintTest class
	instanceVariableNames: ''!


!StdIOReadEvalPrintTest methodsFor: 'tests' stamp: 'JZCH 6/Mar/2026 12:36:27'!
testAlternateTerminator
"Should terminate repl"
	input nextPutAll:
	'self terminator: $? !!
	??
	'.
	
	input reset.
	[repl running] whileTrue: [(Delay forMilliseconds: 5) wait.].
	
	self assert: [repl running not].! !

!StdIOReadEvalPrintTest methodsFor: 'tests' stamp: 'JZCH 6/Mar/2026 12:37:25'!
testDoubleTerminator
"Should terminate repl"
	input nextPutAll: 
	'!!!!
	'.
	
	input reset.
	[repl running] whileTrue: [(Delay forMilliseconds: 5) wait.].
	
	self assert: [repl running not].! !

!StdIOReadEvalPrintTest methodsFor: 'tests' stamp: 'JZCH 6/Mar/2026 12:37:50'!
testEndImmediately
"Should terminate repl"
	input nextPutAll: 
	'self endImmediately!!
	'.
	
	input reset.
	[repl running] whileTrue: [(Delay forMilliseconds: 5) wait.].
	
	self assert: [repl running not].! !

!StdIOReadEvalPrintTest methodsFor: 'tests' stamp: 'JZCH 6/Mar/2026 19:57:17'!
testRerunInput
"Inputs can be rerun"
	| answer |
	input nextPutAll: 
	'1+1!!
	self runPreviousInput!!
	'.
	
	input reset.
	[ answer := repl outputAt: 2.
	  answer isNumber ] whileFalse: [(Delay forMilliseconds: 5) wait.].
	
	self assert: (answer = 2).! !

!StdIOReadEvalPrintTest methodsFor: 'tests' stamp: 'JZCH 7/Mar/2026 21:20:55'!
testReuseBlockClosuresFromOutput
"Block closures can be reused when saved to an output"
	| answer |
	input nextPutAll: 
	'[:a :b | a * b ]!!
	self previousOutput value: 3 value: 5!!
	'.
	
	input reset.
	[ answer := repl outputAt: 2.
	  answer isNumber ] whileFalse: [(Delay forMilliseconds: 5) wait.].
	
	self assert: (answer = 15).! !

!StdIOReadEvalPrintTest methodsFor: 'tests' stamp: 'JZCH 7/Mar/2026 21:22:45'!
testReuseBlockClosuresFromSharedVariables
"Block closures can be reused when saved to a shared variable"
	| answer |
	input nextPutAll: 
	'self assignTo: #aBlock value: [:a :b | a * b ]!!
	(self valueOf: #aBlock) value: 3 value: 5!!
	'.
	
	input reset.
	[ answer := repl outputAt: 2.
	  answer isNumber ] whileFalse: [(Delay forMilliseconds: 5) wait.].
	
	self assert: (answer = 15).! !

!StdIOReadEvalPrintTest methodsFor: 'tests' stamp: 'JZCH 6/Mar/2026 15:28:52'!
testReuseOutput
"Outputs can be retrieved and used as Smalltalk Objects not just a string"
	| answer |
	input nextPutAll: 
	'1!!
	(self previousOutput) + 1!!
	'.
	
	input reset.
	[ answer := repl outputAt: 2.
	  answer isNumber ] whileFalse: [(Delay forMilliseconds: 5) wait.].
	
	self assert: (answer = 2).! !

!StdIOReadEvalPrintTest methodsFor: 'tests' stamp: 'JZCH 7/Mar/2026 21:24:28'!
testSharedVariableScope
"Shared variables are useable within the session"
	| answer |
	input nextPutAll: 
	'self assignTo: #var1 value: 3.
	self assignTo: #var2 value: 5!!
	(self valueOf: #var1) * (self valueOf: #var2)!!
	'.
	
	input reset.
	[ answer := repl outputAt: 2.
	  answer isNumber ] whileFalse: [(Delay forMilliseconds: 5) wait.].
	
	self assert: (answer = 15).! !

!StdIOReadEvalPrintTest methodsFor: 'tests' stamp: 'JZCH 6/Mar/2026 12:42:03'!
testSingleTerminator
"Should evaluate input"
	input nextPutAll: Random next asString.
	input nextPutAll: $!! asString.
	input nextPutAll: Character lf asString.
	
	input reset.
	[repl outputReady] whileFalse: [(Delay forMilliseconds: 5) wait.].
	
	self assert: repl outputReady.! !

!StdIOReadEvalPrintTest methodsFor: 'tests' stamp: 'JZCH 7/Mar/2026 16:46:50'!
testTempVariablesScope
"Temp variables declared in each 'line' of the REPL are accessible only in that line. They are equivalent to private variables within a method"
	| answer |
	input nextPutAll: 
	'| x |
	x := 1!!
	1 + x!!
	'.
	
	input reset.
	[ answer := repl outputAt: 2.
	  answer isString ] whileFalse: [(Delay forMilliseconds: 5) wait.].
	
	self assert: (answer isNumber not).! !

!StdIOReadEvalPrintTest methodsFor: 'setUp/tearDown' stamp: 'JZCH 4/Mar/2026 22:34:59'!
setUp
	input := ReadWriteStream with: ''.
	output := ReadWriteStream with: ''.
	
	repl := StdIOReadEvalPrint new.
	repl stdIn: input.
	repl stdOut: output.
	repl terminator: $!!.
	
	[repl readEvalPrint] fork.! !

!StdIOReadEvalPrintTest methodsFor: 'setUp/tearDown' stamp: 'JZCH 6/Mar/2026 12:19:50'!
tearDown
"Should terminate repl"
	repl endImmediately.
	input nextPutAll: repl terminator asString.
	input nextPutAll: repl terminator asString.
	input nextPutAll: Character lf asString.
	
	input reset.
	[repl running] whileTrue: [(Delay forMilliseconds: 5) wait.].! !
