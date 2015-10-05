fs = require('fs')
bfukt = require('../compiler.coffee')
brainfuck = require('./brainfuck.coffee')

throwOnException = false

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
			test.code = readToNextHeader()
			
			until index >= lines.length or isTitleLine()
				contentName = headerText()
				contentBody = readToNextHeader()
				test[contentName] = contentBody
				
			onTestRead(test)

		onFinished?()

runSafe = (method) ->
	if throwOnException
		return [true, method()]
	else
		try
			return [true, method()]
		catch ex
			return [false, ex]

runTest = (code, input) ->
	[err, compiledCode] = runSafe(() -> bfukt.compile({lines: code})[0])
	if not err
		return [false, 'Compiler: ' + compiledCode]
	
	[err, output] = runSafe(() -> brainfuck.run(compiledCode, input)) 
	if not err
		return [false, 'Interpreter: ' + output]
	
	return [true, output]

runTestAndPrintResult = ({name, code, input, output}) ->
	throw "Dont forget the .. code section" if not code?
	
	output = output?.join('\n') ? ''
	input = input?.join('\n').split('') ? []
	
	[noErrors, result] = runTest(code, input)
	
	additionalText = ''
	str_result = ''
	
	if noErrors	
		wasSuccess = output == result
		
		if wasSuccess
			str_result = 'success'
		else
			str_result = 'failed'
			additionalText = "Expected: \t #{output}\n" +
				"Actual:\t\t #{result}\n"
	else
		str_result = 'error'
		additionalText = result
	
	console.log("'#{name}': #{str_result}\n#{additionalText}\n")
		
readTests(runTestAndPrintResult)
