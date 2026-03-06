'From Cuis7.6 [latest update: #7777] on 6 March 2026 at 9:15:38 pm'!
'Description FileStreams for stdio.  Simple REPL for headless (unwindowed) execution.'!
!provides: 'StdIO' 1 17!
!requires: 'Cuis-Base' 76 7777 nil!
SystemOrganization addCategory: #StdIO!


!classDefinition: #StdIOFileStream category: #StdIO!
UniFileStream subclass: #StdIOFileStream
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'StdIO'!
!classDefinition: 'StdIOFileStream class' category: #StdIO!
StdIOFileStream class
	instanceVariableNames: ''!

!classDefinition: #REPLSession category: #StdIO!
Object subclass: #REPLSession
	instanceVariableNames: 'inputs outputs'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'StdIO'!
!classDefinition: 'REPLSession class' category: #StdIO!
REPLSession class
	instanceVariableNames: ''!

!classDefinition: #StdIOReadEvalPrint category: #StdIO!
Object subclass: #StdIOReadEvalPrint
	instanceVariableNames: 'stdIn stdOut terminator running outputReady session'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'StdIO'!
!classDefinition: 'StdIOReadEvalPrint class' category: #StdIO!
StdIOReadEvalPrint class
	instanceVariableNames: ''!


!StdIOFileStream commentStamp: 'JZCH 5/Mar/2026 20:15:53' prior: 0!
Standard Input/Output/Error FileStreams.

See instance side of Class StdIOReadEvalPrint for usage example.

For VMs on supported OS (currently only Unix and similar - linux and mac), stdin is non blocking when #next is started with #fork and accompanied by Delay #wait.

===

A basic problem/restriction with this code is that currently the VM runs multiple VM threads within a single OS thread.

This means that starting the REPL, even with #fork, BLOCKS THE VM while the VM's OS thread waits on input.

This can be 'fixed' by spawning a 2nd OS thread to block on the stdio.  When that thread wakes up, it can 'sholder tap' the squeak VM to update its state.  Then StdIO acts as just another device driver.!

!REPLSession commentStamp: '<historical>' prior: 0!
I keep copies of inputs and outputs for StdIOReadEvalPrint.

Outputs are returned as Smalltalk Objects and can be reused.

Inputs are strings and can be filed out.
!

!StdIOReadEvalPrint commentStamp: '<historical>' prior: 0!
Very simple Red Eval Print Loop (REPL) for standard input & output.

I respond to "#self".

I keep a copy of previous inputs and outputs. Inputs can be rerun, e.g. self runPreviousInput, self runInputAt: 1. Outputs can be reused, e.g. self previousOutput, self outputAt: 1.

[(StdIOReadEvalPrint newWithDefaults) readEvalPrint] fork. "Blocks image unless running on supported VM on Unix like process"
======
Start Image from command line and invoke code above.
---------------------------------------------
ReadTo!!andPrint> 23 + 4 * 7 !!
189
ReadTo!!andPrint> self previousOutput / 3 !!
63
ReadTo!!andPrint> | x |
x := 'foo'.
x at: 3 put: $x.
x!!
fox
ReadTo!!andPrint> Feature require: #'Morphic-ColorEditor'.!!
Feature
ReadTo!!andPrint> !!!!
----------------------------------
The !!!! above exits!

!StdIOFileStream methodsFor: 'primitives' stamp: 'JZCH 4/Mar/2026 11:49:03'!
primSQFileSetNonBlocking: aSQFileStruct
	"Pass a struct SQFile on the stack, and call fcntl() to set the file non-blocking."
	"This belongs higher on the inheritance hierarchy and should be removed when the feature is implemented in the Cuis base image."

	<primitive: 'primitiveSQFileSetNonBlocking' module: 'UnixOSProcessPlugin'>
	^ nil
! !

!StdIOFileStream methodsFor: 'primitives' stamp: 'JZCH 4/Mar/2026 11:49:07'!
setNonBlocking
	"Convert ioHandle to an SQFile data structure and call primitive to set it non-blocking."
	"This belongs higher on the inheritance hierarchy and should be removed when the feature is implemented in the Cuis base image."

	^ self primSQFileSetNonBlocking: fileID! !

!StdIOFileStream methodsFor: 'file open/close' stamp: 'KenD 24/Jan/2016 16:04:00'!
openOnHandle: aFileID name: streamName forWrite: writeMode
	"Initialize the file with the given handle. If writeMode is true then
	 allow writing, otherwise put the file in read-only mode.
	 N.B. Do _not_ register the stream.  We do not want it to be
	 closed implicitly (e.g. on GC).  There may be multiple instances
	 accessing the same stream.  The stream is not a file."
	fileID := aFileID.
	name := streamName.
	rwmode := writeMode.
	buffer1 := String new: 1.
	self enableReadBuffering! !

!StdIOFileStream class methodsFor: 'instance creation' stamp: 'KenD 24/Jan/2016 16:08:00'!
stderr
	| newSelf |
	newSelf := self new.
	newSelf 
		openOnHandle: self stderrHandle 
		name: 'stderr'
		forWrite: true.
	^newSelf! !

!StdIOFileStream class methodsFor: 'instance creation' stamp: 'JZCH 4/Mar/2026 09:33:03'!
stdin
	| newSelf |
	newSelf := self new useCharacters.
	newSelf 
		openOnHandle: self stdinHandle 
		name: 'stdin'
		forWrite: false.
	newSelf setNonBlocking.
	^newSelf! !

!StdIOFileStream class methodsFor: 'instance creation' stamp: 'KenD 24/Jan/2016 16:07:00'!
stdout
	| newSelf |
	newSelf := self new.
	newSelf 
		openOnHandle: self stdoutHandle 
		name: 'stdout'
		forWrite: true.
	^newSelf! !

!StdIOFileStream class methodsFor: 'accessing' stamp: 'KenD 24/Jan/2016 16:01:00'!
stderrHandle

	^ self stdioHandles at: 3! !

!StdIOFileStream class methodsFor: 'accessing' stamp: 'KenD 24/Jan/2016 16:01:00'!
stdinHandle

	^ self stdioHandles at: 1! !

!StdIOFileStream class methodsFor: 'accessing' stamp: 'KenD 24/Jan/2016 15:44:00'!
stdioHandles
" answer handles: #(stdin stdout stderr) "
	<primitive: 'primitiveFileStdioHandles' module: 'FilePlugin' error: ec>
	self primitiveFailed! !

!StdIOFileStream class methodsFor: 'accessing' stamp: 'KenD 24/Jan/2016 16:01:00'!
stdoutHandle

	^ self stdioHandles at: 2! !

!REPLSession methodsFor: 'accessing' stamp: 'JZCH 6/Mar/2026 14:03:42'!
addInput: anObject
	^ inputs add: anObject! !

!REPLSession methodsFor: 'accessing' stamp: 'JZCH 6/Mar/2026 14:03:39'!
addOutput: anObject
	^ outputs add: anObject! !

!REPLSession methodsFor: 'accessing' stamp: 'JZCH 6/Mar/2026 15:20:52'!
currentIndex
"This is the one we care about"
	^ outputs size + 1! !

!REPLSession methodsFor: 'accessing' stamp: 'JZCH 6/Mar/2026 14:15:51'!
inputAt: index
	^ [ inputs at: index ] ifError: [:err :ex | 'Invalid index' ]! !

!REPLSession methodsFor: 'accessing' stamp: 'JZCH 6/Mar/2026 14:16:05'!
outputAt: index
	^ [ outputs at: index ] ifError: [:err :ex | 'Invalid index' ]! !

!REPLSession methodsFor: 'accessing' stamp: 'JZCH 6/Mar/2026 14:12:56'!
previousInput
	inputs size = 0 ifTrue: [^ nil].
	^ inputs last! !

!REPLSession methodsFor: 'accessing' stamp: 'JZCH 6/Mar/2026 14:12:58'!
previousOutput
	outputs size = 0 ifTrue: [^ nil].
	^ outputs last! !

!REPLSession methodsFor: 'accessing' stamp: 'JZCH 6/Mar/2026 16:35:09'!
saveContentsOn: aStream
	self currentIndex < 2 ifTrue: [^ self].
	
	1 to: self currentIndex - 1 do: [:index |
		aStream nextPutAll: (index asString , ' :').
		aStream newLine.
		aStream nextPutAll: (inputs at: index) asString.
		aStream newLine; nextPutAll: '-----'; newLine.
		aStream nextPutAll: (outputs at: index) asString.
		aStream newLine; nextPutAll: '====='.
		aStream newLine.]! !

!REPLSession methodsFor: 'initialization' stamp: 'JZCH 6/Mar/2026 14:01:53'!
initialize
	super initialize.
	inputs := OrderedCollection new.
	outputs := OrderedCollection new.! !

!StdIOReadEvalPrint methodsFor: 'initialization' stamp: 'JZCH 6/Mar/2026 14:04:04'!
initialize
	super initialize.
	
	outputReady := false.
       running := false.
	session := REPLSession new.
	! !

!StdIOReadEvalPrint methodsFor: 'private' stamp: 'JZCH 6/Mar/2026 19:55:51'!
runInput: aString
"Do not call this manually!!"
	^ Compiler evaluate: aString for: self logged: false! !

!StdIOReadEvalPrint methodsFor: 'user interface' stamp: 'JZCH 6/Mar/2026 21:13:24'!
commands
"Returns a list of my commands intended for the REPL"
	| pragmas selectors return count |
	
	pragmas := Pragma allNamed: #stdioreplcommand in: self class.
	selectors := pragmas collect: [:aPragma | aPragma selector].
	return := ''.
	count := 0.
	selectors do: [:selector | 
		count := count + 1.
		return := return , selector , ' '.
		count = 5 ifTrue:[
			return := return , Character lf asString.
			count := 0]].
	^ return! !

!StdIOReadEvalPrint methodsFor: 'user interface' stamp: 'JZCH 6/Mar/2026 21:01:20'!
endImmediately
"Force stop the loop"

	running := false.
	^ 'Loop force stopped - should use double terminator during normal use instead'! !

!StdIOReadEvalPrint methodsFor: 'user interface' stamp: 'JZCH 6/Mar/2026 21:14:20'!
help
"Show help text"
	|characterString|
	characterString := self terminator asString.
    	^ 
	'End Smalltalk espressions with ' , characterString , ' and press enter to evaluate' , 
	Character newLineCharacter asString ,
	characterString , characterString , ' to close REPL' , 
	Character newLineCharacter asString ,
	'Enter "self help!!" to show this message, "self commands!!" for a list of commands'  ,
	Character newLineCharacter asString! !

!StdIOReadEvalPrint methodsFor: 'user interface' stamp: 'JZCH 6/Mar/2026 20:52:53'!
inputAt: index
<stdioreplcommand>
	^ session inputAt: index! !

!StdIOReadEvalPrint methodsFor: 'user interface' stamp: 'JZCH 6/Mar/2026 20:53:04'!
outputAt: index
<stdioreplcommand>
	^ session outputAt: index! !

!StdIOReadEvalPrint methodsFor: 'user interface' stamp: 'JZCH 6/Mar/2026 20:53:08'!
previousInput
<stdioreplcommand>
	^ session previousInput! !

!StdIOReadEvalPrint methodsFor: 'user interface' stamp: 'JZCH 6/Mar/2026 20:53:11'!
previousOutput
<stdioreplcommand>
	^ session previousOutput! !

!StdIOReadEvalPrint methodsFor: 'user interface' stamp: 'JZCH 6/Mar/2026 20:53:15'!
runInputAt: index
<stdioreplcommand>
	^ self runInput: (self inputAt: index)
	! !

!StdIOReadEvalPrint methodsFor: 'user interface' stamp: 'JZCH 6/Mar/2026 20:53:22'!
runPreviousInput
<stdioreplcommand>
	^ self runInput: self previousInput
	! !

!StdIOReadEvalPrint methodsFor: 'user interface' stamp: 'JZCH 6/Mar/2026 20:53:32'!
saveContents
"Saves the inputs and outputs to a file"
	<stdioreplcommand>
	| fileName |
	fileName := 'Session: ' , DateAndTime now asString.
	
	self saveContentsTo: fileName asFileEntry.
	^ 'Saved to ' , fileName asString! !

!StdIOReadEvalPrint methodsFor: 'user interface' stamp: 'JZCH 6/Mar/2026 20:53:40'!
saveContentsTo: aFileEntry
"Saves the contents to the given filename"
<stdioreplcommand>

	aFileEntry writeStreamDo: [ :fileStream |
		fileStream ifNotNil: [ 
			session saveContentsOn: fileStream ]].
	^ 'Saved to ' , aFileEntry asString! !

!StdIOReadEvalPrint methodsFor: 'accessing' stamp: 'JZCH 6/Mar/2026 15:11:21'!
currentIndex
	^ session currentIndex! !

!StdIOReadEvalPrint methodsFor: 'accessing' stamp: 'JZCH 4/Mar/2026 22:41:46'!
outputReady
"Hook for testing and debugging"
	^ outputReady! !

!StdIOReadEvalPrint methodsFor: 'accessing' stamp: 'JZCH 6/Mar/2026 15:11:26'!
prompt
"Edit this to customise the prompt"
    ^ self currentIndex asString, ' ', self terminator asString, '> '! !

!StdIOReadEvalPrint methodsFor: 'accessing' stamp: 'JZCH 4/Mar/2026 20:33:34'!
quitSmalltalkOnClose
"Todo: Figure out how to run headless
Set to true to shutdown vm when REPL closes. Not critical when running in GUI mode."
	^ false | Smalltalk isHeadless! !

!StdIOReadEvalPrint methodsFor: 'accessing' stamp: 'JZCH 4/Mar/2026 22:42:13'!
running
"Hook for testing and debugging"
    ^ running! !

!StdIOReadEvalPrint methodsFor: 'accessing' stamp: 'JZCH 4/Mar/2026 20:23:03'!
stdIn: aFileStream
	stdIn := aFileStream! !

!StdIOReadEvalPrint methodsFor: 'accessing' stamp: 'JZCH 4/Mar/2026 20:23:07'!
stdOut: aFileStream
	stdOut := aFileStream! !

!StdIOReadEvalPrint methodsFor: 'accessing' stamp: 'JZCH 4/Mar/2026 20:24:34'!
terminator
"Character to signal end of input. Default is $!!. Send terminator: to change.
Using anything outside of ASCII Basic Latin (codePoint 31-126) is unsafe. VM/Terminal may not pass the right value"
    ^ terminator ifNil: [terminator := Character codePoint: 33]! !

!StdIOReadEvalPrint methodsFor: 'accessing' stamp: 'JZCH 4/Mar/2026 20:24:51'!
terminator: aCharacter
"Character to signal end of input.
Using anything outside of ASCII Basic Latin (codePoint 31-126) is unsafe. VM/Terminal may not pass the right value"
    aCharacter isString ifTrue: [terminator := aCharacter first. ^ self].
    terminator := aCharacter! !

!StdIOReadEvalPrint methodsFor: 'finalization' stamp: 'JZCH 6/Mar/2026 11:57:27'!
doClosingActions
	stdOut flush. self show: 'Exiting'. self show: String newLineString.
	self quitSmalltalkOnClose ifTrue: [Smalltalk quit]! !

!StdIOReadEvalPrint methodsFor: 'command line' stamp: 'JZCH 6/Mar/2026 19:56:17'!
readEvalPrint
	| line output |
	
       self show: self help.
       "Must be set immediately prior"
	running := true.
	[ line := self request: self prompt.
	  outputReady := false.
	  line size = 0
	] whileFalse: [
		output := [ self runInput: line ] ifError: [ :err :ex | err ].
		session addInput: line.
		session addOutput: output.
		self show: output.
		self show: String newLineString.
		outputReady := true.
		self running ifFalse: [ ^ self doClosingActions "Being forced to end"].
	].
       "Must be set immediately after"
       running := false.
       self doClosingActions.! !

!StdIOReadEvalPrint methodsFor: 'command line' stamp: 'JZCH 4/Mar/2026 23:07:34'!
request: prompt
	"Display prompt, gather text until CR"
	| line char |
	line := ''.
	self show: prompt.
	[true] whileTrue: [
		char := stdIn next.
		(char = $!!) ifTrue: [ ^ line ].
		char ifNotNil: [line := line , char asString].
		(Delay forMilliseconds: 50) wait.
	]! !

!StdIOReadEvalPrint methodsFor: 'command line' stamp: 'JZCH 4/Mar/2026 20:22:54'!
show: anObject

	stdOut nextPutAll: anObject asString! !

!StdIOReadEvalPrint class methodsFor: 'instance creation' stamp: 'JZCH 5/Mar/2026 22:32:23'!
newWithDefaults
	| newInstance |
	newInstance := self new.
	newInstance stdIn: StdIOFileStream stdin.
	newInstance stdOut: StdIOWriteStream stdout.
	newInstance terminator: $!!.
	
	^ newInstance! !
