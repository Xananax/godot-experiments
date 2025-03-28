## Parsegg is a simple parser combinator library for GDScript.
##
## Inspired by Haskell's Parsec library
class_name Parsegg extends EditorScript

################################################################################
## 
## PARSER CONTEXT
## 
################################################################################


## Creates a new [Context] object.
static func context(new_text: String, new_index: int = 0) -> Context:
	return Context.new(new_text, new_index)


## Holds the current state of the parser.
##
## Used throughout a parser run to keep track of the current position in the input
class Context:
	## the text being parsed
	var text: String
	## the current index in the text
	var index: int

	func _init(new_text: String, new_index: int = 0):
		text = new_text
		index = new_index


################################################################################
## 
## RESULT UTILITIES
## 
################################################################################


## A result of a parser run. can be either a success or a failure.
##
## The base class isn't used directly, but defines the interface.
## The runtime will always use wither [Success] or [Failure] objects.
class Result:

	var is_success := false

	var context: Context
	
	
	func _init(new_context: Context):
		context = new_context


## A failure result of a parser run.
##
## This is returned when a parser fails to match the input.
class Failure extends Result:

	var expected: String

	func _init(new_context: Context, new_expected: String) -> void:
		super._init(new_context)
		expected = new_expected
		is_success = false
	

	func _to_string() -> String:
		return "Parse error, expected %s at char %s"%[expected, context.index]


## A success result of a parser run.
##
## This is returned when a parser successfully matches the input.
## The value of the match is stored in the [member value] property.
class Success extends Result:
	
	var value: Variant

	func _init(new_context: Context, new_value):
		super._init(new_context)
		value = new_value
		is_success = true


################################################################################
## 
## PARSER BASE CLASS
## intended to be extended in subclasses
## 
################################################################################


## The base class for all parsers.
##
## This class defines the interface for all parsers.
class Parser:

	## The main entry point for the parser.
	## This method is called to parse the input text.
	func parse(text: String) -> Result:
		var context := Context.new(text)
		return run(context)


	## The main parsing method.
	## This method is called by the [method parse] method.
	func run(context: Context) -> Result:
		return Failure.new(context, "Base Parser class is not supposed to be called")


################################################################################
## 
## STRING PARSER
## 
################################################################################


## Returns a new [StringParser] object.
static func string(new_str_match: String) -> StringParser:
	return StringParser.new(new_str_match)


## Match a string exactly
## 
## This parser will match an exact string.
class StringParser extends Parser:

	var str_match: String

	func _init(new_str_match: String) -> void:
		str_match = new_str_match

	func run(context: Context) -> Result:
		if context.index + str_match.length() <= context.text.length():
			var substring = context.text.substr(context.index, str_match.length())
			if substring == str_match:
				var new_context = Context.new(context.text, context.index + str_match.length())
				return Success.new(new_context, str_match)
		return Failure.new(context, str_match)


################################################################################
## 
## SEQUENCE PARSER
## 
################################################################################

## Returns a new [SequenceParser] object.
static func sequence(new_parsers_list: Array[Parser]) -> SequenceParser:
	return SequenceParser.new(new_parsers_list)


## Matches a sequence of parsers in order.
##
## This parser will match a sequence of parsers in order.
## It will return a list of the values returned by each parser.
class SequenceParser extends Parser:
	var parsers_list: Array[Parser]

	func _init(new_parsers_list: Array[Parser]) -> void:
		parsers_list = new_parsers_list

	func run(context: Context) -> Result:
		var values_list := []
		var next_context := context
		for parser in parsers_list:
			var result := parser.run(next_context)
			if not result.is_success:
				return result
			values_list.append(result.value)
			next_context = result.context
		return Success.new(next_context, values_list)


################################################################################
## 
## REGEX PARSER
## 
################################################################################


## Returns a new [RegExpParser] object.
static func regex(pattern: String, expected: String) -> RegExpParser:
	var regular_expression := RegEx.new()
	if regular_expression.compile(pattern) != OK:
		printerr("regex failed to compile: %s" % [pattern])
	return RegExpParser.new(regular_expression, expected)


## Matches a regular expression.
##
## This parser will match a regular expression.
class RegExpParser extends Parser:
	var regular_expression: RegEx
	var expected: String

	func _init(new_regular_expression: RegEx, new_expected: String) -> void:
		regular_expression = new_regular_expression
		expected = new_expected

	func run(context: Context) -> Result:
		var regex_match := regular_expression.search(context.text, context.index)
		if regex_match and regex_match.get_start() == context.index:
			return Success.new(Context.new(context.text, regex_match.get_end()), regex_match.get_string())
		return Failure.new(context, expected)


################################################################################
## 
## ANY PARSER
## 
################################################################################


## Returns a new [AnyParser] object.
static func any(new_parsers_list: Array[Parser]) -> AnyParser:
	return AnyParser.new(new_parsers_list)


## This parser will try each parser in the list in order.
##
## Tries each parser in order, starting from the same point in the input.
## return the first one that succeeds. or return the failure that got furthest
## in the input string. which failure to return is a matter of taste, we prefer
## the furthest failure because. it tends be the most useful / complete error
## message. any time you see several choices in a grammar, you'll use `any`
class AnyParser extends Parser:
	var parsers_list: Array[Parser]

	func _init(new_parsers_list: Array[Parser]) -> void:
		parsers_list = new_parsers_list

	func run(context: Context) -> Result:
		var furthest_result: Result
		for parser in parsers_list:
			var result := parser.run(context)
			if result.is_success:
				return result
			if not furthest_result or (furthest_result.context.index < result.context.index):
				furthest_result = result
		return furthest_result



################################################################################
## 
## OPTIONAL PARSER
## 
################################################################################


## Returns a new [OptionalParser] object.
static func optional(new_parser: Parser) -> OptionalParser:
	return OptionalParser.new(new_parser)


## Matches a potential parser.
##
## This parser will match a parser, or succeed with null if no match is found.
class OptionalParser extends AnyParser:
	
	func _init(new_parser: Parser) -> void:
		super._init([new_parser, TrueParser.new()])


################################################################################
## 
## BOOLEAN/IDENTITY PARSERS
## 
################################################################################

## A parser that always succeeds.
##
## This parser will always succeed and return null.
## It is an implementation detail and used in other parsers.
class TrueParser extends Parser:
	func run(context: Context) -> Result:
		return Success.new(context, null)


## A parser that always fails.
##
## This parser will always fails and return an empty string.
## It is an implementation detail and used in other parsers.
class FalseParser extends Parser:
	func run(context: Context) -> Result:
		return Failure.new(context, "")


################################################################################
## 
## MANY PARSERS
## 
################################################################################


## Returns a new [ManyParser] object.
static func many(new_parser: Parser) -> ManyParser:
	return ManyParser.new(new_parser)


## Matches a parser zero or more times.
##
## This parser will match a parser zero or more times.
## It will return a list of the values returned by each parser.
## It will stop when the parser fails.
## This parser never fails, it can only succeed with an empty list.
class ManyParser extends Parser:
	var parser: Parser

	func _init(new_parser: Parser) -> void:
		parser = new_parser

	func run(context: Context) -> Result:
		var values_list := []
		var next_context := context
		while true:
			var result := parser.run(next_context)
			if not result.is_success:
				break
			values_list.append(result.value)
			next_context = result.context
		return Success.new(next_context, values_list)


################################################################################
## 
## MAP UTILITY
## 
################################################################################


## Returns a new [MappingParser] object.
static func map(new_parser: Parser, new_fn: Callable) -> MappingParser: 
	return MappingParser.new(new_parser, new_fn)


## A parser that maps the result of another parser to a function.
##
## This parser will run another parser and pass the result to a function.
## It will return the result of the function.
## This is useful for transforming the result of a parser into a different
## type.
## It's useful for common things like building AST nodes from input strings.
## Failures are passed through untouched.
class MappingParser extends Parser:
	var parser: Parser
	var fn: Callable

	func _init(new_parser: Parser, new_fn: Callable) -> void:
		parser = new_parser
		fn = new_fn

	func run(context: Context) -> Result:
		var result := parser.run(context)
		if not result.is_success:
			return result
		var mapped_result = fn.call(result.value)
		return Success.new(result.context, mapped_result)


################################################################################
## 
## FORWARD REF UTILITY
## 
################################################################################


## Returns a new [ForwardRef] object.
static func forward_ref() -> ForwardRef:
	return ForwardRef.new()


## Handles cyclic references in parsers.
##
## Because GDScript can't handle cyclic references in classes, we need to use a
## special parser to handle forward references.
## This parser will hold a reference to another parser and run it when needed.
class ForwardRef extends Parser:
	var _parser: Parser = null

	func set_parser(parser: Parser) -> void:
		_parser = parser

	func run(context: Context) -> Result:
		if _parser == null:
			return Failure.new(context, "Forward reference not set")
		return _parser.run(context)
