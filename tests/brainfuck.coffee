findMatching = (code, incDepth, decDepth, index, delta) ->
	depth = 1
	while depth > 0
		index += delta
		switch code[index]
			when incDepth then depth++
			when decDepth then depth--
	
	return index
			
run = (code, inputs) ->
	index = 0
	memory = []
	output = ''
	pc = 0
		
	while pc < code.length
		switch code[pc]
			when '>' 
				index++
				pc++
				
			when '<'
				if index == 0
					throw "Pointer index can not go below 0"
				index--
				pc++
				
			when '+'
				memory[index] = ((memory[index] ? 0) + 1) % 256
				pc++
				
			when '-'
				value = (memory[index] ? 0) - 1
				if value == -1 
					value = 255
				memory[index] = value
				pc++
				
			when '.'
				output += String.fromCharCode(memory[index] ? 0)
				pc++
				
			when ','
				if inputs.length == 0
					throw "No input to read"
				memory[index] = inputs.shift().charCodeAt(0)
				pc++
				
			when '['
				if not memory[index]	
					pc = findMatching(code, '[', ']', pc, 1)
				pc++
				
			when ']'
				pc = findMatching(code, ']', '[', pc, -1)
				
			else
				throw "Invalid char '#{code[pc]}'"
		
	return output

if window?
	exports = window.brainfuck = {}
else
	exports = module.exports = {}

exports.run = run
