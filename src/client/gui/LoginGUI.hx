package gui;

import defold.support.GuiScript;
import defold.support.ScriptOnInputAction;
import dirtylarry.DirtyLarry;

typedef LoginGUIData = {
	var username:String;
}

class LoginGUI extends defold.support.GuiScript<LoginGUIData> {
	override function init(self:LoginGUIData) {
		Msg.post(".", GoMessages.acquire_input_focus);

		self.username = "";
	}

	override function on_input(self:LoginGUIData, action_id:Hash, action:ScriptOnInputAction):Bool {
		// bind inputs
		self.username = DirtyLarry.input(self, "username", action_id, action, Gui.GuiKeyboardType.KEYBOARD_TYPE_DEFAULT, "Pick a username");

		// bind buttons
		DirtyLarry.button(self, "join", action_id, action, function() {
			if (self.username == "")
				return;

			Msg.post("/controller", Messages.Login, {
				username: self.username,
			});
		});

		DirtyLarry.button(self, "quit", action_id, action, function() {
			Msg.post("@system:", SysMessages.exit, {code: 0});
		});

		DirtyLarry.button(self, "skinPicker", action_id, action, function() {
			Msg.post("/controller", Messages.IncrementSkin);
		});

		return true;
	}
}
