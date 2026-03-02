'From Cuis7.6 [latest update: #7777] on 2 March 2026 at 9:45:22 pm'!
'Description FileStreams for stdio.  Simple REPL for headless (unwindowed) execution.'!
!provides: 'StdIO' 1 8!
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
	instanceVariableNames: 'stdin stdout delimiter running'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'StdIO'!
!classDefinition: 'StdIOReadEvalPrint class' category: #StdIO!
StdIOReadEvalPrint class
	instanceVariableNames: ''!


!StdIOFileStream commentStamp: '<historical>' prior: 0!
Standard Input/Output/Error FileStreams.

See instance side of Class StdIOReadEvalPrint for usage example.


A basic problem/restriction with this code is that currently the VM runs multiple VM threads within a single OS thread.

This means that starting the REPL, even with #fork, BLOCKS THE VM while the VM's OS thread waits on input.

This can be 'fixed' by spawning a 2nd OS thread to block on the stdio.  When that thread wakes up, it cah 'sholder tap' the squeak VM to update its state.  Then StdIO acts as Just abother device driver.

The solution abive is not done at this time because the VM builders are already working on a general solution which will work with all FFI callbacks.  The general solution will allow multiple OS threads interacting with a single VM thread.

We should adopt this solution when available.
!

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

!StdIOFileStream class methodsFor: 'instance creation' stamp: 'JZCH 27/Feb/2026 17:25:51'!
stdin
	| newSelf |
	newSelf := self new useCharacters.
	newSelf 
		openOnHandle: self stdinHandle 
		name: 'stdin'
		forWrite: false.
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

!StdIOReadEvalPrint methodsFor: 'initialization' stamp: 'JZCH 2/Mar/2026 21:15:44'!
initialize

	super initialize.
	stdin := StdIOFileStream stdin.
	stdout := StdIOFileStream stdout.
       self delimiter.
       running := false.
	! !

!StdIOReadEvalPrint methodsFor: 'accessing' stamp: 'JZCH 2/Mar/2026 21:40:44'!
delimiter
"Character to signal end of input. Default is $!!. Call delimiter: to change.
Using anything outside of ASCII Basic Latin (codePoint 31-126) is unsafe. VM/Terminal may not pass the right value"
    ^ delimiter ifNil: [delimiter := Character codePoint: 33]! !

!StdIOReadEvalPrint methodsFor: 'accessing' stamp: 'JZCH 2/Mar/2026 21:41:19'!
delimiter: aCharacter
"Character to signal end of input.
Using anything outside of ASCII Basic Latin (codePoint 31-126) is unsafe. VM/Terminal may not pass the right value"
    aCharacter isString ifTrue: [delimiter := aCharacter first. ^ self].
    delimiter := aCharacter! !

!StdIOReadEvalPrint methodsFor: 'accessing' stamp: 'JZCH 2/Mar/2026 21:25:06'!
helpText
|characterString|
    characterString := self delimiter asString.
    ^ 'End Smalltalk espressions with ', characterString, 'and press enter to evaluate', 
        Character newLineCharacter asString,
        characterString, characterString, ' to close REPL' , Character newLineCharacter asString.! !

!StdIOReadEvalPrint methodsFor: 'accessing' stamp: 'JZCH 2/Mar/2026 21:26:36'!
prompt
"Edit this to customise the prompt"
    ^ 'ReadTo', self delimiter asString, 'andPrint> '! !

!StdIOReadEvalPrint methodsFor: 'accessing' stamp: 'JZCH 27/Feb/2026 22:14:31'!
quitSmalltalkOnClose
"Todo: Figure out how to run headless
Set to true to shutdown vm when REPL closes. Not critical when running in GUI mode."
	^ false! !

!StdIOReadEvalPrint methodsFor: 'accessing' stamp: 'JZCH 2/Mar/2026 21:16:58'!
running
"For testing. True if within REPL loop"
    ^ running! !

!StdIOReadEvalPrint methodsFor: 'command line' stamp: 'JZCH 2/Mar/2026 21:18:17'!
readEvalPrint
	| line |
	
       self show: self helpText.
       "Must be set immediately prior"
	running := true.
	[ line := self request: self prompt.
	  line size = 0
	] whileFalse: [
		self show: ( [ Compiler evaluate: line ] ifError: [ :err :ex | err ] ).
		self show: String newLineString.
	].
       "Must be set immediately after"
       running := false.
       self quitSmalltalkOnClose ifTrue: [Smalltalk quit]! !

!StdIOReadEvalPrint methodsFor: 'command line' stamp: 'JZCH 2/Mar/2026 21:18:33'!
request: prompt
	"Display prompt, gather text until CR"
	| line char |
	line := ''.
	self show: prompt.
	[true] whileTrue: [
		char := stdin next.
		(char = self delimiter) ifTrue: [ ^ line ].
		line := line , char asString.
	]! !

!StdIOReadEvalPrint methodsFor: 'command line' stamp: 'KenD 24/Jan/2016 16:20:00'!
show: anObject

	stdout nextPutAll: anObject asString! !
