'From Cuis7.6 [latest update: #7777] on 4 March 2026 at 10:56:53 pm'!
'Description FileStreams for stdio.  Simple REPL for headless (unwindowed) execution.'!
!provides: 'StdIO' 1 9!
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

!classDefinition: #StdIOReadEvalPrint category: #StdIO!
Object subclass: #StdIOReadEvalPrint
	instanceVariableNames: 'stdIn stdOut terminator running readLine outputReady'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'StdIO'!
!classDefinition: 'StdIOReadEvalPrint class' category: #StdIO!
StdIOReadEvalPrint class
	instanceVariableNames: ''!


!StdIOFileStream commentStamp: 'JZCH 4/Mar/2026 11:45:37' prior: 0!
Standard Input/Output/Error FileStreams.

See instance side of Class StdIOReadEvalPrint for usage example.

For VMs on supported OS (currently only Unix and similar - linux and mac), stdin is non blocking when REPL is started with #fork.

===

A basic problem/restriction with this code is that currently the VM runs multiple VM threads within a single OS thread.

This means that starting the REPL, even with #fork, BLOCKS THE VM while the VM's OS thread waits on input.

This can be 'fixed' by spawning a 2nd OS thread to block on the stdio.  When that thread wakes up, it can 'sholder tap' the squeak VM to update its state.  Then StdIO acts as just another device driver.!

!StdIOReadEvalPrint commentStamp: '<historical>' prior: 0!
Very simple Red Eval Print Loop (REPL) for standard input & output..

Note also: Transcripter>>readEvalPrint.

[(StdIOReadEvalPrint new) readEvalPrint] fork. "Blocks image until done"
======
Start Image from command line and invoke code above.
---------------------------------------------
ReadTo!!andPrint> 23 + 4 * 7 / 3 !!
63
ReadTo!!andPrint> 23 + 4 * 7!!
189
ReadTo!!andPrint> | x |
x := 'foo'.
x at: 3 put: $x.
x!!
fox
ReadTo!!andPrint> Feature require: #'Morphic-ColorEditor'.!!
Feature
ReadTo!!andPrint> !!!!
nil
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

!StdIOReadEvalPrint methodsFor: 'initialization' stamp: 'JZCH 4/Mar/2026 22:17:03'!
initialize

	super initialize.
	
	outputReady := false.
       running := false.
	! !

!StdIOReadEvalPrint methodsFor: 'accessing' stamp: 'JZCH 4/Mar/2026 20:56:57'!
helpText
|characterString|
    characterString := self terminator asString.
    ^ 'End Smalltalk espressions with ', characterString, ' and press enter to evaluate', 
        Character newLineCharacter asString,
        characterString, characterString, ' to close REPL' , Character newLineCharacter asString.! !

!StdIOReadEvalPrint methodsFor: 'accessing' stamp: 'JZCH 4/Mar/2026 22:41:46'!
outputReady
"Hook for testing and debugging"
	^ outputReady! !

!StdIOReadEvalPrint methodsFor: 'accessing' stamp: 'JZCH 4/Mar/2026 20:26:11'!
prompt
"Edit this to customise the prompt"
    ^ 'ReadTo', self terminator asString, 'andPrint> '! !

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

!StdIOReadEvalPrint methodsFor: 'command line' stamp: 'JZCH 4/Mar/2026 22:42:46'!
readEvalPrint
	| line |
	
       self show: self helpText.
       "Must be set immediately prior"
	running := true.
	[ line := self request: self prompt.
	  outputReady := false.
	  line size = 0
	] whileFalse: [
		self show: ( [ Compiler evaluate: line ] ifError: [ :err :ex | err ] ).
		self show: String newLineString.
		outputReady := true.
	].
       "Must be set immediately after"
       running := false.
       stdOut flush. self show: 'Exiting'. self show: String newLineString.
       self quitSmalltalkOnClose ifTrue: [Smalltalk quit]! !

!StdIOReadEvalPrint methodsFor: 'command line' stamp: 'JZCH 4/Mar/2026 22:53:26'!
request: prompt
	"Display prompt, gather text until CR"
	| line char |
	line := ''.
	self show: prompt.
	[true] whileTrue: [
		char := stdIn next.
		(char = $!!) ifTrue: [ ^ line ].
		char ifNotNil: [readLine := line , char asString].
		(Delay forMilliseconds: 50) wait.
	]! !

!StdIOReadEvalPrint methodsFor: 'command line' stamp: 'JZCH 4/Mar/2026 20:22:54'!
show: anObject

	stdOut nextPutAll: anObject asString! !

!StdIOReadEvalPrint class methodsFor: 'instance creation' stamp: 'JZCH 4/Mar/2026 20:29:47'!
newWithDefaults
	| newInstance |
	newInstance := self new.
	newInstance stdIn: StdIOFileStream stdin.
	newInstance stdOut: StdIOFileStream stdout.
	newInstance terminator: $!!.
	
	^ newInstance! !
