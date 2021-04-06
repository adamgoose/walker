package dirtylarry;

import defold.Gui;
import defold.types.Hash;
import defold.support.ScriptOnInputAction;

@:native("require('dirtylarry/dirtylarry')")
extern class DirtyLarry {
	static function input(self:Dynamic, name:String, acition_id:Hash, action:ScriptOnInputAction, keyboardType:GuiKeyboardType, placeholder:String):String;

	static function button(self:Dynamic, name:String, action_id:Hash, action:ScriptOnInputAction, callback:() -> Void):Void;
}
