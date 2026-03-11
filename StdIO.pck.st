'From Cuis7.6 [latest update: #7777] on 11 March 2026 at 12:32:54 pm'!
'Description FileStreams for stdio.  Simple REPL for headless (unwindowed) execution.'!
!provides: 'StdIO' 1 28!
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
	instanceVariableNames: 'inputs outputs sharedVariables repl'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'StdIO'!
!classDefinition: 'REPLSession class' category: #StdIO!
REPLSession class
	instanceVariableNames: ''!

!classDefinition: #StdIOReadEvalPrint category: #StdIO!
Object subclass: #StdIOReadEvalPrint
	instanceVariableNames: 'stdInPrivateNoREPL stdOutPrivateNoREPL terminatorPrivateNoREPL runningPrivateNoREPL outputReadyPrivateNoREPL sessionPrivateNoREPL quitSmalltalkOnExit stdOutWidthPrivateNoREPL'
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

!REPLSession commentStamp: 'JZCH 7/Mar/2026 21:49:49' prior: 0!
I keep copies of inputs, outputs, and shared variables for StdIOReadEvalPrint.

Outputs are returned as Smalltalk Objects and can be reused.

Inputs are strings and can be filed out.

Shared variables can be created for use between inputs using the messages under 'binding' category. REPL should have messages under 'binding' with the same names.

Shared variables must be named using #Symbols.!

!StdIOReadEvalPrint commentStamp: 'JZCH 9/Mar/2026 15:12:22' prior: 0!
Very simple Read Eval Print Loop (REPL) for standard input & output.

I can be accessed using "self". E.g. send 'self help' or 'self commands' from the REPL.

Shared variables can be declared using messages under the 'binding' category. Share variable names must be #Symbols.

I keep a copy of previous inputs and outputs. Inputs can be rerun, e.g. self rerun, self rerun: 1. Outputs can be reused, e.g. self reuse, self reuse: 1.

Block closures can be created either as output or as shared variable for reuse. 

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

!REPLSession methodsFor: 'binding' stamp: 'JZCH 8/Mar/2026 20:57:12'!
assignTo: aName value: aValue
	<stdioreplcommand>
	aName isSymbol ifFalse: [^ self error: 'Name shared variables with a #Symbol'].
	^ sharedVariables at: aName put: aValue! !

!REPLSession methodsFor: 'binding' stamp: 'JZCH 8/Mar/2026 20:57:16'!
declare: aName
	<stdioreplcommand>
	^ self assignTo: aName value: nil! !

!REPLSession methodsFor: 'binding' stamp: 'JZCH 8/Mar/2026 20:57:20'!
hasDeclared: aName
	<stdioreplcommand>
	^ sharedVariables includesKey: aName! !

!REPLSession methodsFor: 'binding' stamp: 'JZCH 8/Mar/2026 20:57:24'!
sharedVariables
	<stdioreplcommand>
	^ sharedVariables keys! !

!REPLSession methodsFor: 'binding' stamp: 'JZCH 8/Mar/2026 20:57:27'!
sharedVariablesDo: aBlock
	<stdioreplcommand>
	sharedVariables keysDo: aBlock! !

!REPLSession methodsFor: 'binding' stamp: 'JZCH 8/Mar/2026 20:57:31'!
valueOf: aName
	<stdioreplcommand>
	^ sharedVariables at: aName! !

!REPLSession methodsFor: 'user interface' stamp: 'JZCH 9/Mar/2026 20:41:18'!
commands
"Returns a list of my commands"
	<stdioreplcommand>
	| pragmas selectors |
	
	pragmas := Pragma allNamed: #stdioreplcommand in: self class.
	selectors := pragmas collect: [:aPragma | aPragma selector].
	^ self repl printWrappedToWidth: selectors! !

!REPLSession methodsFor: 'user interface' stamp: 'JZCH 8/Mar/2026 21:41:33'!
help
"Show help text"
	<stdioreplcommand>
    	^ 
'Session Manager. Access inputs and outputs. Declare and reuse shared variables.
Save session to file.

Usage:
	self sn <command>

Commands:
	help 				show this text
	commands 			list my commands     	

IO:
	previousInput 			last input
	inputAt:			input at index
	previousOutput 			last output
	outputAt: 			output at index

Saving:
	saveContents 			save session to text file
	saveContentsTo: 		save session to a file 
					Example: self sn saveContentsTo: ''session'' asFileEntry

Shared Variables - names must be #Symbols
	declare: 			put nil at #name
	hasDeclared: 			return true if #name exists
	assignTo:value: 		assign to #name a value
	valueOf: 			retrieve value of #name
	sharedVariables 		list of shared variables
	sharedVariablesDo: 		do a block for each #name
'! !

!REPLSession methodsFor: 'user interface' stamp: 'JZCH 8/Mar/2026 20:58:51'!
inputAt: index
"Code at"
	<stdioreplcommand>
	^ [ inputs at: index ] ifError: [:err :ex | 'Invalid index' ]! !

!REPLSession methodsFor: 'user interface' stamp: 'JZCH 8/Mar/2026 20:58:46'!
outputAt: index
"Object at"
	<stdioreplcommand>
	^ [ outputs at: index ] ifError: [:err :ex | 'Invalid index' ]! !

!REPLSession methodsFor: 'user interface' stamp: 'JZCH 8/Mar/2026 20:58:36'!
previousInput
"The code evaluated for previous input"
	<stdioreplcommand>
	inputs size = 0 ifTrue: [^ nil].
	^ inputs last! !

!REPLSession methodsFor: 'user interface' stamp: 'JZCH 8/Mar/2026 20:58:21'!
previousOutput
"The object returned for previous input"
	<stdioreplcommand>
	outputs size = 0 ifTrue: [^ nil].
	^ outputs last! !

!REPLSession methodsFor: 'user interface' stamp: 'JZCH 8/Mar/2026 20:42:38'!
saveContents
"Saves the inputs and outputs to a file"
	<stdioreplcommand>
	| fileName |
	fileName := 'Session: ' , DateAndTime now asString.
	
	self saveContentsTo: fileName asFileEntry.
	^ 'Saved to ' , fileName asString! !

!REPLSession methodsFor: 'user interface' stamp: 'JZCH 8/Mar/2026 20:43:00'!
saveContentsTo: aFileEntry
"Saves the contents to the given filename"
	<stdioreplcommand>

	aFileEntry writeStreamDo: [ :fileStream |
		fileStream ifNotNil: [ 
			self saveContentsOn: fileStream ]].
	^ 'Saved to ' , aFileEntry asString! !

!REPLSession methodsFor: 'accessing' stamp: 'JZCH 8/Mar/2026 20:48:57'!
addInput: anObject
	^ inputs add: anObject! !

!REPLSession methodsFor: 'accessing' stamp: 'JZCH 8/Mar/2026 20:48:52'!
addOutput: anObject
	^ outputs add: anObject! !

!REPLSession methodsFor: 'accessing' stamp: 'JZCH 6/Mar/2026 15:20:52'!
currentIndex
"This is the one we care about"
	^ outputs size + 1! !

!REPLSession methodsFor: 'accessing' stamp: 'JZCH 8/Mar/2026 20:56:05'!
repl
	^ repl! !

!REPLSession methodsFor: 'accessing' stamp: 'JZCH 8/Mar/2026 20:55:54'!
repl: selfContext
	repl := selfContext! !

!REPLSession methodsFor: 'private' stamp: 'JZCH 6/Mar/2026 16:35:09'!
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

!REPLSession methodsFor: 'initialization' stamp: 'JZCH 7/Mar/2026 17:22:12'!
initialize
	super initialize.
	inputs := OrderedCollection new.
	outputs := OrderedCollection new.
	sharedVariables := Dictionary new.! !

!StdIOReadEvalPrint methodsFor: 'initialization' stamp: 'JZCH 9/Mar/2026 20:07:19'!
initialize
	super initialize.
	
	outputReadyPrivateNoREPL := false.
       runningPrivateNoREPL := false.
	quitSmalltalkOnExit := false.

	sessionPrivateNoREPL := REPLSession new repl: self.
	! !

!StdIOReadEvalPrint methodsFor: 'private' stamp: 'JZCH 9/Mar/2026 20:36:16'!
printWrapped: aCollectionOfStrings before: aNumber
"Terminal may not auto wrap output. Wrap line before a certain number of characters is exceeded"
	| count return |
	count := 0.
	return := ''.
	aCollectionOfStrings do: [:aString | |length|
		length := aString size.
		(count + length) > aNumber ifTrue: [
			return := return , Character lf asString.
			count := 0].
		count := count + length + 1.
		return := return , aString , ' '.
	].
	^ return! !

!StdIOReadEvalPrint methodsFor: 'private' stamp: 'JZCH 9/Mar/2026 20:36:30'!
printWrapped: aCollectionOfStrings every: aNumber
"Terminal may not auto wrap output. Wrap line after a certain number of elements have been printed"
	| count return |
	count := 0.
	return := ''.
	aCollectionOfStrings do: [:aString | 
		count = aNumber ifTrue: [
			return := return , Character lf asString.
			count := 0].
		count := count + 1.
		return := return , aString , ' '.
	].
	^ return! !

!StdIOReadEvalPrint methodsFor: 'private' stamp: 'JZCH 9/Mar/2026 20:40:54'!
printWrappedToWidth: aCollectionOfStrings
"Terminal may not auto wrap output. Wrap line before width of the output is exceeded"
	^ self printWrapped: aCollectionOfStrings before: self stdOutWidth! !

!StdIOReadEvalPrint methodsFor: 'private' stamp: 'JZCH 6/Mar/2026 19:55:51'!
runInput: aString
"Do not call this manually!!"
	^ Compiler evaluate: aString for: self logged: false! !

!StdIOReadEvalPrint methodsFor: 'user interface' stamp: 'JZCH 9/Mar/2026 20:41:33'!
commands
"Returns a list of my commands intended for the REPL"
	<stdioreplcommand>
	| pragmas selectors |
	
	pragmas := Pragma allNamed: #stdioreplcommand in: self class.
	selectors := pragmas collect: [:aPragma | aPragma selector].
	^ self printWrappedToWidth: selectors! !

!StdIOReadEvalPrint methodsFor: 'user interface' stamp: 'JZCH 7/Mar/2026 22:27:47'!
endImmediately
"Force stop the loop. Deliberately leaving this off the pragma list"

	runningPrivateNoREPL := false.
	^ 'Loop force stopped - should use double terminator during normal use instead'! !

!StdIOReadEvalPrint methodsFor: 'user interface' stamp: 'JZCH 9/Mar/2026 21:26:46'!
help
"Show help text"
	<stdioreplcommand>
    	^ 
'Inputs are valid Smalltalk, except for the character marking end of input.
No other special characters or keywords are parsed.
Access instance with messages to ''self''.

Usage:
	self <command> [subcommand]

Commands:
	intro 				show quick help
	help 				show this text
	commands 			list my commands
	sn 				session manager

Reuse:
	rerun 				reevaluate last input
	rerun:				reevaluate input at index
	reuse 				last output
	reuse: 				output at index
	use: 				shared variable #name, declared via session manager
	
Others:
	terminator: 			change character used to mark end of input
					recommend limiting to ASCII Basic Latin (codePoint 31-126)
					other characters may not be passed correctly by the VM/terminal
					use only strictly when necessary, $!! is a good default
	privateVariables: 		list of variables that should *not be* reassigned
	stdOutWidth: 			long lines should wrap before this is exceeded
'! !

!StdIOReadEvalPrint methodsFor: 'user interface' stamp: 'JZCH 9/Mar/2026 20:30:03'!
intro
"Show intro help text"
	<stdioreplcommand>
	|characterString|
	characterString := self terminator asString.
    	^ 
	'End Smalltalk espressions with ' , characterString , ' and press enter to evaluate' , 
	Character newLineCharacter asString ,
	characterString , characterString , ' to close REPL, Smalltalk quits as well: ' , 
	quitSmalltalkOnExit asString , 
	Character newLineCharacter asString ,
	'Enter "self help!!" for help, "self commands!!" for a list of commands
	Enter "self intro!!" to show this message'  ,
	Character newLineCharacter asString! !

!StdIOReadEvalPrint methodsFor: 'user interface' stamp: 'JZCH 9/Mar/2026 20:41:44'!
privateVariables
	<stdioreplcommand>
	^ 
'As the REPL is accessible via "self", all instance variables of the REPL are also accessible.
You should not need to read them directly. You should definitely not change them from the REPL.
They are deliberately named contrary to Smalltalk convention to prevent accidental conflicts:' , 
String newLineString , (self printWrappedToWidth: (self class instVarNames))! !

!StdIOReadEvalPrint methodsFor: 'user interface' stamp: 'JZCH 9/Mar/2026 15:11:47'!
rerun
	<stdioreplcommand>
	^ self runInput: self sn previousInput
	! !

!StdIOReadEvalPrint methodsFor: 'user interface' stamp: 'JZCH 9/Mar/2026 15:11:33'!
rerun: index
	<stdioreplcommand>
	^ self runInput: (self sn inputAt: index)
	! !

!StdIOReadEvalPrint methodsFor: 'user interface' stamp: 'JZCH 9/Mar/2026 15:13:02'!
reuse
"Convenience message"
	<stdioreplcommand>
	^ self sn previousOutput! !

!StdIOReadEvalPrint methodsFor: 'user interface' stamp: 'JZCH 9/Mar/2026 15:13:08'!
reuse: anIndex
"Convenience message"
	<stdioreplcommand>
	^ self sn outputAt: anIndex! !

!StdIOReadEvalPrint methodsFor: 'user interface' stamp: 'JZCH 8/Mar/2026 20:35:20'!
sn
	<stdioreplcommand>
	^ sessionPrivateNoREPL! !

!StdIOReadEvalPrint methodsFor: 'user interface' stamp: 'JZCH 9/Mar/2026 21:21:59'!
use: aSymbol
"Convenience message"
	<stdioreplcommand>
	^ self sn valueOf: aSymbol! !

!StdIOReadEvalPrint methodsFor: 'accessing' stamp: 'JZCH 8/Mar/2026 20:45:28'!
currentIndex
	^ self sn currentIndex! !

!StdIOReadEvalPrint methodsFor: 'accessing' stamp: 'JZCH 7/Mar/2026 15:56:02'!
outputReady
"Hook for testing and debugging"
	^ outputReadyPrivateNoREPL! !

!StdIOReadEvalPrint methodsFor: 'accessing' stamp: 'JZCH 6/Mar/2026 15:11:26'!
prompt
"Edit this to customise the prompt"
    ^ self currentIndex asString, ' ', self terminator asString, '> '! !

!StdIOReadEvalPrint methodsFor: 'accessing' stamp: 'JZCH 7/Mar/2026 15:57:15'!
running
"Hook for testing and debugging"
    ^ runningPrivateNoREPL! !

!StdIOReadEvalPrint methodsFor: 'accessing' stamp: 'JZCH 9/Mar/2026 20:27:15'!
setQuitSmalltalkOnExit
"Issue: Smalltalk isHeadless doesn't appear to retrieve any VM flags, #vmOptionsDo: always end up with a nil array. The flags sent to image do nothing on MacOS, GUI starts as usual.

To start a headless VM, send -headless flag to VM, prior to the image path.

If the REPL exits with !!!!, the image is not closed properly and will complain next time it is opened in GUI mode. Must send Smalltalk quit!! to exit. Therefore, tell REPL when opened in headless VM mode it should quit the image on exit.

Not critical when running in GUI mode."
	quitSmalltalkOnExit := true! !

!StdIOReadEvalPrint methodsFor: 'accessing' stamp: 'JZCH 7/Mar/2026 15:57:45'!
stdIn: aFileStream
	stdInPrivateNoREPL := aFileStream! !

!StdIOReadEvalPrint methodsFor: 'accessing' stamp: 'JZCH 7/Mar/2026 15:57:57'!
stdOut: aFileStream
	stdOutPrivateNoREPL := aFileStream! !

!StdIOReadEvalPrint methodsFor: 'accessing' stamp: 'JZCH 9/Mar/2026 20:39:42'!
stdOutWidth
	^ stdOutWidthPrivateNoREPL ifNil: [stdOutWidthPrivateNoREPL := 110]! !

!StdIOReadEvalPrint methodsFor: 'accessing' stamp: 'JZCH 9/Mar/2026 20:39:14'!
stdOutWidth: aNumber
	stdOutWidthPrivateNoREPL := aNumber! !

!StdIOReadEvalPrint methodsFor: 'accessing' stamp: 'JZCH 7/Mar/2026 15:58:06'!
terminator
"Character to signal end of input. Default is $!!. Send terminator: to change.
Using anything outside of ASCII Basic Latin (codePoint 31-126) is unsafe. VM/Terminal may not pass the right value"
    ^ terminatorPrivateNoREPL ifNil: [terminatorPrivateNoREPL := Character codePoint: 33]! !

!StdIOReadEvalPrint methodsFor: 'accessing' stamp: 'JZCH 7/Mar/2026 15:58:06'!
terminator: aCharacter
"Character to signal end of input.
Using anything outside of ASCII Basic Latin (codePoint 31-126) is unsafe. VM/Terminal may not pass the right value"
    aCharacter isString ifTrue: [terminatorPrivateNoREPL := aCharacter first. ^ self].
    terminatorPrivateNoREPL := aCharacter! !

!StdIOReadEvalPrint methodsFor: 'finalization' stamp: 'JZCH 9/Mar/2026 20:11:10'!
doClosingActions
	stdOutPrivateNoREPL flush. self show: 'Exiting'. self show: String newLineString.
	quitSmalltalkOnExit ifTrue: [Smalltalk quit]! !

!StdIOReadEvalPrint methodsFor: 'command line' stamp: 'JZCH 8/Mar/2026 21:19:48'!
readEvalPrint
	| line output |
	
       self show: self intro.
       "Must be set immediately prior"
	runningPrivateNoREPL := true.
	[ line := self request: self prompt.
	  outputReadyPrivateNoREPL := false.
	  line size = 0
	] whileFalse: [
		output := [ self runInput: line ] ifError: [ :err :ex | err ].
		self sn addInput: line.
		self sn addOutput: output.
		self show: output.
		self show: String newLineString.
		outputReadyPrivateNoREPL := true.
		self running ifFalse: [ ^ self doClosingActions "Being forced to end"].
	].
       "Must be set immediately after"
       runningPrivateNoREPL := false.
       self doClosingActions.! !

!StdIOReadEvalPrint methodsFor: 'command line' stamp: 'JZCH 7/Mar/2026 21:43:40'!
request: prompt
	"Display prompt, gather text until CR"
	| line char |
	line := ''.
	self show: prompt.
	[true] whileTrue: [
		char := stdInPrivateNoREPL next.
		(char = $!!) ifTrue: [ ^ line ].
		char ifNotNil: [line := line , char asString].
		(Delay forMilliseconds: 15) wait.
	]! !

!StdIOReadEvalPrint methodsFor: 'command line' stamp: 'JZCH 7/Mar/2026 15:57:57'!
show: anObject

	stdOutPrivateNoREPL nextPutAll: anObject asString! !

!StdIOReadEvalPrint class methodsFor: 'instance creation' stamp: 'JZCH 5/Mar/2026 22:32:23'!
newWithDefaults
	| newInstance |
	newInstance := self new.
	newInstance stdIn: StdIOFileStream stdin.
	newInstance stdOut: StdIOWriteStream stdout.
	newInstance terminator: $!!.
	
	^ newInstance! !

!StdIOReadEvalPrint class methodsFor: 'instance creation' stamp: 'JZCH 9/Mar/2026 20:12:30'!
newWithDefaultsHeadless
	^ self newWithDefaults setQuitSmalltalkOnExit! !
