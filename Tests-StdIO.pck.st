'From Cuis7.6 [latest update: #7777] on 4 March 2026 at 10:57:45 pm'!
'Description '!
!provides: 'Tests-StdIO' 1 0!
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


!StdIOReadEvalPrintTest methodsFor: 'tests' stamp: 'JZCH 4/Mar/2026 22:50:45'!
testAlternateTerminator
"Should terminate repl"
	repl terminator: $?.
	input nextPutAll: '??'.
	input nextPutAll: Character lf asString.
	
	input reset.
	[repl running] whileTrue: [(Delay forMilliseconds: 5) wait.].
	
	self assert: [repl running not].! !

!StdIOReadEvalPrintTest methodsFor: 'tests' stamp: 'JZCH 4/Mar/2026 22:41:13'!
testDoubleTerminator
"Should terminate repl"
	input nextPutAll: '!!!!'.
	input nextPutAll: Character lf asString.
	
	input reset.
	[repl running] whileTrue: [(Delay forMilliseconds: 5) wait.].
	
	self assert: [repl running not].! !

!StdIOReadEvalPrintTest methodsFor: 'tests' stamp: 'JZCH 4/Mar/2026 22:41:00'!
testSingleTerminator
"Should evaluate input"
| contents |
	input nextPutAll: Random next asString.
	input nextPutAll: $!! asString.
	input nextPutAll: Character lf asString.
	
	input reset.
	[repl outputReady] whileFalse: [(Delay forMilliseconds: 5) wait.].
	contents := output contents.
	
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
