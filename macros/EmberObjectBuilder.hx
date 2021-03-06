/*
Copyright (C) 2012 Dave Keen http://www.actionscriptdeveloper.co.uk

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software
is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

package macros;

#if neko

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;
import tink.core.types.Outcome;
using tink.macro.tools.MacroTools;
using macros.tools.ArrayTools;

class EmberObjectBuilder {
	
	@:macro static public function build():Array<Field> {
		var fields = Context.getBuildFields();
		var cls = Context.getLocalClass().get();
		
		var newFields = [];
		
		// Go through all the fields in this class
		for (field in fields) {
			// We are only interested in public instance attributes
			if (field.access.contains(APublic) && !field.access.contains(AStatic)) {
				// Get the type out of the FVar
				var readType = switch (field.kind) {
					case FVar(readType, _): readType;
					default: null;
				}
				
				// Only continue if readType was set, otherwise this is a function not a variable
				if (readType != null) {
					// 1. Create getter and setters for each field that delegates to Ember.Object's get() and set() methods
					field.kind = FProp("__$get_" + field.name, "__$set_" + field.name, readType);
					
					var getterExprString = Std.format("function():Dynamic { return get('${field.name}'); }");
					newFields.push({
						name: "__$get_" + field.name,
						doc: null,
						meta: [],
						access: [APrivate, AInline],
						kind: FFun(getFunction(Context.parse(getterExprString, Context.currentPos()))),
						pos: Context.currentPos()
					});
					
					var setterExprString = Std.format("function(value:Dynamic):Dynamic { return set('${field.name}', value); }");
					newFields.push({
						name: "__$set_" + field.name,
						doc: null,
						meta: [],
						access: [APrivate, AInline],
						kind: FFun(getFunction(Context.parse(setterExprString, Context.currentPos()))),
						pos: Context.currentPos()
					});
				}
			}
		}
		
		for (newField in newFields)
			fields.push(newField);
			
		return fields;
	}
	
	private static function getFunction(e:Expr) {
		return
			switch (e.expr) { 
				case EFunction(_, f): f;
				default: throw "Not an EFunction!";
			};
	}
	
}

#end