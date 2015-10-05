## Easier to simply write a parser for these tests
fs = require('fs')
bfukt = require('../compiler.coffee')
brainfuck = require('../brainfuck.coffee')

String::startsWith ?= (s) -> @indexOf(s) == 0
String::isWhitespace = () -> @trim().length == 0

assert = (message, condition) -> throw message unless condition

readTests = (onTestRead, onFinished) ->
	fs.readFile 'test_code.txt', 'utf8', (err, data) ->
		if err
			return console.log("File error: err")
		
		lines = data.split(/\r?\n/)
		index = 0
		
		isHeader = () ->
			return lines[index].startsWith('.')
		
		readToNextHeader = ()->
			if isHeader()
				index++
			
			start = index
			while index < lines.length and !isHeader()
				index++
			
			end = if lines[index - 1].isWhitespace() then index - 1  else index
			
			return lines[start...end]
		
		headerText = () ->
			return (lines[index]).match(/^\.+ (.*)$/)[1]
		
		isTitleLine = () ->
			return lines[index].startsWith('. ')
		
		while index < lines.length
			assert("Should be on title line", isTitleLine())
			test = { name: headerText() }
			readToNextHeader()
			
			until index >= lines.length or isTitleLine()
				contentName = headerText()
				contentBody = readToNextHeader()
				test[contentName] = contentBody
				
			onTestRead(test)

		onFinished?()
		
runTest = ({name, code, input, output}) ->
	output = output?.join('\n') ? ''
	input = input?.split('') ? []
	
	compiled_code = bfukt.compile({lines: code})[0]
	actual_output = brainfuck.run(compiled_code, input)
	
	wasSuccess = output == actual_output
	result = "'#{name}': #{wasSuccess}\n"
	if !wasSuccess
		result += "Expected: \t #{output}\n"
		result += "Actual:\t\t #{actual_output}\n"
	
	console.log(result)
		
readTests(runTest)
