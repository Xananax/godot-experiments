@tool
extends "./parsegg.gd"

## 
var expr := forward_ref()


var number_literal := map(
	regex("[+\\-]?[0-9]+(\\.[0-9]*)?", "number"),
	func (token:String): return token.to_float()
)

var ident := regex("[a-zA-Z][a-zA-Z0-9]*", "identifier")

var trailing_arg := map(
	sequence([string(","), expr]),
	func (results: Array): return results[1]
);


var args = map(
	sequence([expr, many(trailing_arg)]),
	func (results: Array): return [results[0]] + results[1]
);

var func_call := map(
	sequence(
		([ident, string("("), optional(args), string(")")] as Array[Parser])
	),
	func (results: Array): return ({
		"type": "Call",
		"fn_name": results[0],
		"args": results[2] if results.size() > 1 else []
	})
)

func parse_example(text: String) -> void:
	prints("will attempt to parse:", "`%s`"%[text])
	var result := expr.parse(text)
	if result.is_success:
		prints(result.value);
	else:
		printerr(result)
	print("----------------------------------------------------------------")

func _run():
	expr.set_parser(any([func_call, number_literal]))

	parse_example("1");
	parse_example("Foo()");
	parse_example("Foo(Bar())");
	parse_example("Foo(Bar(1,2,3))");
	
