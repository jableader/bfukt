String::repeat = (n) ->
	return new Array(n+1).join(this)

String::isNumeric = () ->
	return !isNaN(parseFloat(this)) && isFinite(this)
	
String::isLiteral = () ->
	return this.isNumeric() or (this.length == 3 and this[0] == '\'' and this[2] == '\'') 

String::literalValue = () ->
	return if this.isNumeric() then parseInt(this) else this.charCodeAt(1)

class Pointer
	constructor: (@value) ->
		@isEmpty = true
	
	goto: (from, ignoreNotEmpty = true) -> 
		if not (@isEmpty or ignoreNotEmpty)
			throw "Attempted to access a potentially non empty variable"
		
		ch = (if from.value > @value then "<" else ">")
		return ch.repeat(Math.abs(from.value - @value))
	

class MemoryManager
	constructor: () ->
		@i = 0
		@freed = []
	
	free: (pt, isEmpty) ->
		if isEmpty? 
			pt.isEmpty = isEmpty
		
		@freed.push(pt)

	claim: (pt) ->
		index = @freed.indexOf(pt)
		if index == -1 and pt.value < @i
			throw "Cant claim owned pointer " + pt.value
		else
			temp = @freed[index]
			@freed[index] = @freed[0]
			@freed.shift()
						
			return temp
		
	malloc: (near) ->
		if @freed.length == 0
			return new Pointer(@i++)
		
		if not near?
			smallest = (r, l) -> if r.value < l.value then r else l
			return @claim(@freed.reduce(smallest, new Pointer(Infinity)))
			
		near = near.value
		[nearest_index, nearest_value] = [-1, Math.abs(@i - near)]
		for f, i in @freed
			if Math.abs(f.value-near) < nearest_value
				[nearest_index, nearest_value] = [i, Math.abs(f.value-near)] 
		
		if nearest_index = -1
			return new Pointer(@i++)
		else
			return @claim(@freed[nearestIndex])

Memory = new MemoryManager()

[IF, WHILE, OPEN, FUNCTION] = ['IF', 'WHILE', 'OPEN', 'FUNCTION']
SCOPES = [IF, WHILE, OPEN, FUNCTION]
class Scope	
	constructor: (@parent, @type) ->
		if not (@type in SCOPES)
			throw "Unknown type '#{@type}'";
		@vars = {}
		
	get: (name) ->
		if @vars[name]?
			return @vars[name]
		else if @parent?
			value = @parent.get(name)
			if value?
				return value
		throw "Unknown variable '#{name}'"

	malloc: (name, near) ->
		if name?
			if name of @vars
				throw 'Cant redim at same scope'
			else if name == 'in'
				throw 'Cant dim name in'
			
			return @vars[name] = Memory.malloc(near)
		else
			pt = Memory.malloc(near)
			pt.isEmpty = not @inLoop()
			
			return pt
	
	define: (name, pt) ->
		if @vars[name]? 
			throw "Cant redefine #{name} at the same scope"
		@vars[name] = pt
	
	free: (pt, isEmpty) ->
		Memory.free(pt, isEmpty)
		
	enter: (type) -> 
		return new Scope(this, type)
		
	exit: () ->
		if @parent?
			for name, pt of @vars
				unless pt instanceof Func
					Memory.free(pt)
		else
			Memory = new MemoryManager()
		return @parent
		
	inLoop: ()->
		return @type != WHILE or (@parent? and @parent.inLoop())		

class Func
	constructor: (@argumentNames, @lines) -> 
	
	call: (in_pt, parentScope, argPts) ->
		if argPts.length != @argumentNames.length
			throw "Incorrect number of parameters"
		
		myScope = parentScope.enter(FUNCTION)
		for i in [0...@argumentNames.length]
			myScope.define(@argumentNames[i], argPts[i])
		
		childArgs = { scope: myScope, lines: @lines, in_pt: in_pt }
		
		result = parse(childArgs, FUNCTION)
		myScope.exit()
		
		return result
		
gotoDo = (in_pt, getPt, code, destinations...) ->
	s = ""
	for destination in destinations
		pt = getPt(destination)
		
		s += pt.goto(in_pt) + code(destination)
		in_pt = pt
	
	return [s, in_pt]

performAtPointers = (in_pt, keep, source, destinations...) ->
	[s, pt] = ['', in_pt]
	if keep
		temp = Memory.malloc(source)
		destinations.push({pt: temp, ch: '+'})
		[s, pt] = clearPointers(pt, temp)
	
	destinations.push({pt: source, ch: '-'})
	
	[s2, out_pt] = gotoDo(source, ((d) -> d.pt), ((d) -> d.ch), destinations...)
	setEmpty(false, destinations...)
	
	s += source.goto(in_pt) + "[" + s2 + "]"
	setEmpty(true, source)
	
	if keep
		[add_s, out_pt] = performAtPointers(out_pt, false, temp, {pt: source, ch: '+'})
		s += add_s
		Memory.free(temp, true)
		setEmpty(false, source)
	
	return [s, out_pt]

setEmpty = (state, pts...) -> 
	for pt in pts
		pt.isEmpty = state

setToLiteral = (in_pt, value, pts...) ->
	[clearString, pt] = clearPointers(in_pt, pts.filter((p) -> p.clear).map((p) -> p.pt)...)
	if value < 10 or  pts.length == 1
		[s, pt] = gotoDo(pt, ( (d) -> d.pt ), ( (d) -> d.ch.repeat(value) ), pts...)
	else
		temp = Memory.malloc(pts[0])
		
		[s, pt] = setToLiteral(pt, value, {pt: temp, ch: '+'})
		[s2, pt] = performAtPointers(in_pt, false, temp, pts...)
		
		Memory.free(temp, true)
		s += s2
	
	setEmpty(false, pts.map((p) -> p.pt)...)
	return [clearString + s, pt]
	
clearPointers = (in_pt, pts...) ->
	s = ""
	for pt in pts
		if not pt.isEmpty
			s += pt.goto(in_pt) + '[-]'
			pt.isEmpty = true
			in_pt = pt
	
	return [s, in_pt]

parse_multidim = (args) ->
	args.r[1].split(', ').forEach( (name) -> args.scope.malloc(name) )
	return ["", args]
	
 #['-foo', 'bar'] = [{ch: '-', clear: false, pt: *foo}, {'ch':'+', clear:true, pt: *bar}]
parseMultiDestinations = (s, scope) -> 
	return s.split(', ').map (d) ->
		clear = d[0] != '+' and d[0] != '-'
		varName = if clear then d else d.substring(1)
		ch = if d[0] == '-' then '-' else '+'
		return { pt: scope.get(varName), ch: ch, clear: clear }
	
parse_multiset_in = (args) ->
	vars = args.r[1].split(', ').map( (d) -> args.scope.get(d) )
	
	[s, args.in_pt] = gotoDo(args.in_pt, ((pt) -> pt), (() -> ','), vars...)
	return [s, args]
	
parse_dim_multiset = (args) ->
	r = args.r
	vars = r[1].split(', ').map( (d) -> {pt: args.scope.malloc(d), ch: '+'} )
	
	if r[2] == '_in'
		[s, args.in_pt] = gotoDo(args.in_pt, ((d) -> d.pt), (() -> ','), vars...)
	
	else
		#Since we cannot gaurentee its value is zero, we must clear it
		[s, args.in_pt] = clearPointers(args.in_pt, vars.map( (d) -> d.pt )...)
		
		if r[2].isLiteral()
			[s2, args.in_pt] = setToLiteral(args.in_pt, r[2].literalValue(), vars...)
			
		else
			keep = not r[2].startsWith('_')
			sourcePt = args.scope.get(if keep then r[2] else r[2].substring(1))
			
			[s2, args.in_pt] = performAtPointers(args.in_pt, keep, sourcePt, vars...)
		s += s2
	
	return [s, args]

	
parse_multiset = (args) ->
	r = args.r
	destinations = parseMultiDestinations(r[1], args.scope)
	[s, args.in_pt] = clearPointers(args.in_pt, destinations.filter( (d) -> d.clear ).map( (d) -> d.pt )...)
	
	if r[2].isLiteral()
		[s2, args.in_pt] = setToLiteral(args.in_pt, r[2].literalValue(), destinations...)
	else
		keep = not r[2].startsWith('_')
		sourceName = if keep then r[2] else r[2].substring(1)
		[s2, args.in_pt] = performAtPointers(args.in_pt, keep, args.scope.get(sourceName), destinations...)
	
	return [s + s2, args]


findInnerCodeEnd = (start, lines) ->
	first_ws = lines[start].match(/^\s*/)[0]
	matcher = new RegExp("^#{first_ws}\\S")
	
	for i in [start+1...lines.length]
		if lines[i].match(matcher)
			return i-1
	
	return lines.length - 1
	
if_statement = (in_pt, innerArgs, ifPt, keep, getInnerCode) ->
	s = ifPt.goto(in_pt) + "["
	innerArgs.in_pt = ifPt
	
	[innerCode, in_pt] = getInnerCode(innerArgs)
	
	s += innerCode
	
	if keep
		ifPtCopy = Memory.malloc(ifPt)
		[clearCode, in_pt] = performAtPointers(in_pt, false, ifPt, {pt: ifPtCopy, ch: '+'})
	else
		[clearCode, in_pt] = clearPointers(in_pt, ifPt)
	
	s += clearCode + ifPt.goto(in_pt) + "]"
	in_pt = ifPt
	
	if keep
		[s2, in_pt] = performAtPointers(in_pt, false, ifPtCopy, {pt: ifPt, ch: '+'})
		Memory.free(ifPtCopy, true)
		s += s2
	
	return [s, in_pt]


parse_if = (args) ->
	innerCodeEnd = findInnerCodeEnd(args.index, args.lines)
	ifPt = args.scope.get(args.r[2])
	keep = not args.r[1].startsWith('_')
	hasElse = args.lines[innerCodeEnd+1]?.trim() == "else"
	
	innerCodeArgs = {lines: args.lines[args.index+1..innerCodeEnd], scope: args.scope}
	
	if hasElse
		notIfPt = Memory.malloc(ifPt)
		s = notIfPt.goto(args.in_pt) + '+'
		notIfPt.isEmpty = false
		
		innerCode = (innerIfArgs) ->
			innerS = notIfPt.goto(innerIfArgs.in_pt) + '-'
			innerIfArgs.in_pt = notIfPt
			[innerS2, innerIfArgs.in_pt] = parse(innerIfArgs, IF)
			return [innerS + innerS2, innerIfArgs.in_pt]
		
		[s2, args.in_pt] = if_statement(notIfPt, innerCodeArgs, ifPt, keep, innerCode)
		s += s2
		
		elseCodeEnd = findInnerCodeEnd(innerCodeEnd+1, args.lines)
		innerCodeArgs = {scope: args.scope, lines: args.lines[innerCodeEnd+2..elseCodeEnd]}
		[s2, args.in_pt] = if_statement(args.in_pt, innerCodeArgs, notIfPt, false, (args) -> parse(args, IF))
		s += s2
		
		Memory.free(notIfPt)
		args.index = elseCodeEnd
		return [s, args]
		
	else
		[s, args.in_pt] = if_statement(args.in_pt, innerCodeArgs, ifPt, keep, (args) -> parse(args, IF))
		args.index = innerCodeEnd
		return [s, args]
	
parse_while = (args) ->
	{r, lines, scope} = args
	innerCodeEnd = findInnerCodeEnd(args.index, lines)
	whilePt = scope.get(r[2])
	decOrInc = if r[1] then r[1] else ""
	
	innerArgs = {in_pt: whilePt, scope: scope, lines: lines[args.index+1..innerCodeEnd]}
	[innerCode, out_pt] = parse(innerArgs, WHILE)
	s = whilePt.goto(args.in_pt) + "[" + innerCode + whilePt.goto(out_pt) + decOrInc + "]"
	
	args.index = innerCodeEnd
	args.in_pt = whilePt
	setEmpty(true, whilePt)
	
	return [s, args]
		
parse_print = (args) ->
	vars = args.r[1].split(', ').map( (name) -> args.scope.get(name) )
	[s, args.in_pt] = gotoDo(args.in_pt, ((d) -> d), (() -> '.'), vars...)
	return [s, args]

parse_function = (args) ->
	{r, scope, in_pt, lines} = args
	innerCodeEnd = findInnerCodeEnd(args.index, lines)
	[name, argNames] = [r[1], r[2].split(', ')]
	
	func = new Func(argNames, lines[args.index+1..innerCodeEnd])
	scope.define(name, func)
	
	args.index = innerCodeEnd
	return ["", args]
	
parse_function_call = (args) ->
	{r, scope, in_pt} = args
	func = scope.get(r[1])
	argsPts = r[2].split(', ').map((name) -> scope.get(name))
	
	[s, out_pt] = func.call(in_pt, scope, argsPts)
	args.in_pt = out_pt
	
	return [s, args]
	
	
parse_nothing = (args) -> ["", args]

statements = [
	[/^$/, parse_nothing]
	[/^#/, parse_nothing]
	[/^print ((?:[a-zA-Z]+, )*[a-zA-Z]+)$/, parse_print]
	[/^var ((?:[a-zA-Z]+, )*[a-zA-Z]+)$/, parse_multidim]
	[/^var ((?:[a-zA-Z]+, )*[a-zA-Z]+) = (\d+|'.'|_?[a-zA-Z]+)$/, parse_dim_multiset]
	[/^((?:[a-zA-Z]+, )*[a-zA-Z]+) = _in$/, parse_multiset_in]
	[/^((?:(?:\+|-)?[a-zA-Z]+, )*(?:\+|-)?[a-zA-Z]+) = (\d+|'.'|_?[a-zA-Z]+)$/, parse_multiset]
	[/^if (_?)([a-zA-Z]+)$/, parse_if]
	[/^while ((?:\+|-)?)([a-zA-Z]+)$/, parse_while]
	[/^def ([a-zA-Z]+)\(((?:[a-zA-Z]+, )*[a-zA-Z]+)\)$/, parse_function]
	[/^([a-zA-Z]+)\(((?:[a-zA-Z]+, )*[a-zA-Z]+)\)$/, parse_function_call]
]

parse = (args, type) ->
	s = ""
	args.index ?= -1
	args.in_pt ?= new Pointer(0)
	args.scope = if args.scope? then args.scope.enter(type) else new Scope(undefined, OPEN)
	
	try
		while ++args.index < args.lines.length
			lc = undefined
			line = args.lines[args.index].trim()
			for statement in statements
				if (args.r = line.match(statement[0]))
					[lc, args] = statement[1].call(null, args)
					break
			
			if lc?
				s += lc
			else
				throw "Syntax error at #{args.index}\n#{line}"
	catch ex
		throw "Error: #{ex}\n#{args.index}: #{line}"
	
	args.scope = args.scope.exit()
	return [s, args.in_pt]
	
window.parse = parse
window.optimise = (s) -> s
