'From Cuis 4.2 of 25 July 2013 [latest update: #2676] on 27 January 2016 at 11:57:52.273497 am'!
'Description FileStreams for stdio.  Simple REPL for headless (unwindowed) execution.'!
!provides: 'StdIO' 1 6!
!classDefinition: #StdIOReadEvalPrint category: #StdIO!
Object subclass: #StdIOReadEvalPrint
	instanceVariableNames: 'stdin stdout'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'StdIO'!
!classDefinition: 'StdIOReadEvalPrint class' category: #StdIO!
StdIOReadEvalPrint class
	instanceVariableNames: ''!

!classDefinition: #StdIOFileStream category: #StdIO!
StandardFileStream subclass: #StdIOFileStream
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'StdIO'!
!classDefinition: 'StdIOFileStream class' category: #StdIO!
StdIOFileStream class
	instanceVariableNames: ''!


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

!StdIOFileStream commentStamp: '<historical>' prior: 0!
Standard Input/Output/Error FileStreams.

See instance side of Class StdIOReadEvalPrint for usage example.


A basic problem/restriction with this code is that currently the VM runs multiple VM threads within a single OS thread.

This means that starting the REPL, even with #fork, BLOCKS THE VM while the VM's OS thread waits on input.

This can be 'fixed' by spawning a 2nd OS thread to block on the stdio.  When that thread wakes up, it cah 'sholder tap' the squeak VM to update its state.  Then StdIO acts as Just abother device driver.

The solution abive is not done at this time because the VM builders are already working on a general solution which will work with all FFI callbacks.  The general solution will allow multiple OS threads interacting with a single VM thread.

We should adopt this solution when available.
!

!StdIOReadEvalPrint methodsFor: 'initialization' stamp: 'KenD 1/24/2016 16:14'!
initialize

	super initialize.
	stdin := StdIOFileStream stdin.
	stdout := StdIOFileStream stdout.
	! !

!StdIOReadEvalPrint methodsFor: 'command line' stamp: 'KenD 1/24/2016 18:31'!
readEvalPrint
	| line |
	
	[ line := self request: 'ReadTo!!andPrint> '.
	  line size = 0
	] whileFalse: [
		self show: ( [ Compiler evaluate: line ] ifError: [ :err :ex | err ] ).
		self show: String newLineString.
	]! !

!StdIOReadEvalPrint methodsFor: 'command line' stamp: 'KenD 1/24/2016 18:23'!
request: prompt
	"Display prompt, gather text until CR"
	| line char |
	line := ''.
	self show: prompt.
	[true] whileTrue: [
		char := stdin next.
		(char = $!!) ifTrue: [ ^ line ].
		line := line , char asString.
	]! !

!StdIOReadEvalPrint methodsFor: 'command line' stamp: 'KenD 1/24/2016 16:20'!
show: anObject

	stdout nextPutAll: anObject asString! !

!StdIOFileStream methodsFor: 'file open/close' stamp: 'KenD 1/24/2016 16:04'!
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

!StdIOFileStream class methodsFor: 'instance creation' stamp: 'KenD 1/24/2016 16:08'!
stderr
	| newSelf |
	newSelf := self new.
	newSelf 
		openOnHandle: self stderrHandle 
		name: 'stderr'
		forWrite: true.
	^newSelf! !

!StdIOFileStream class methodsFor: 'accessing' stamp: 'KenD 1/24/2016 16:01'!
stderrHandle

	^ self stdioHandles at: 3! !

!StdIOFileStream class methodsFor: 'instance creation' stamp: 'KenD 1/24/2016 16:07'!
stdin
	| newSelf |
	newSelf := self new.
	newSelf 
		openOnHandle: self stdinHandle 
		name: 'stdin'
		forWrite: false.
	^newSelf! !

!StdIOFileStream class methodsFor: 'accessing' stamp: 'KenD 1/24/2016 16:01'!
stdinHandle

	^ self stdioHandles at: 1! !

!StdIOFileStream class methodsFor: 'accessing' stamp: 'KenD 1/24/2016 15:44'!
stdioHandles
" answer handles: #(stdin stdout stderr) "
	<primitive: 'primitiveFileStdioHandles' module: 'FilePlugin' error: ec>
	self primitiveFailed! !

!StdIOFileStream class methodsFor: 'instance creation' stamp: 'KenD 1/24/2016 16:07'!
stdout
	| newSelf |
	newSelf := self new.
	newSelf 
		openOnHandle: self stdoutHandle 
		name: 'stdout'
		forWrite: true.
	^newSelf! !

!StdIOFileStream class methodsFor: 'accessing' stamp: 'KenD 1/24/2016 16:01'!
stdoutHandle

	^ self stdioHandles at: 2! !
