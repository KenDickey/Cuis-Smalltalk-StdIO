'From Cuis 4.2 of 25 July 2013 [latest update: #2658] on 24 January 2016 at 6:42:04.820472 pm'!
'Description FileStreams for stdio.  Simple REPL for headless (unwindowed) execution.'!
!provides: 'StdIO' 1 5!
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
ReadTo!!andPrint> !!!!
nil
----------------------------------
The !!!! above exits!

!StdIOFileStream commentStamp: '<historical>' prior: 0!
Standard Input/Output/Error FileStreams!

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
