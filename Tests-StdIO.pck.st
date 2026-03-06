'From Cuis7.6 [latest update: #7777] on 6 March 2026 at 4:48:14 pm'!
'Description '!
!provides: 'Tests-StdIO' 1 2!
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

!StdIOReadEvalPrintTest methodsFor: 'tests' stamp: 'JZCH 6/Mar/2026 12:42:03'!
testSingleTerminator
"Should evaluate input"
	input nextPutAll: Random next asString.
	input nextPutAll: $!! asString.
	input nextPutAll: Character lf asString.
	
	input reset.
	[repl outputReady] whileFalse: [(Delay forMilliseconds: 5) wait.].
	
	self assert: repl outputReady.! !

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
