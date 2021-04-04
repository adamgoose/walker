package gui;

import defold.support.GuiScript;
import defold.support.ScriptOnInputAction;
import dirtylarry.DirtyLarry;

typedef LoginGUIData = {
	var email:String;
	var password:String;
}

class LoginGUI extends defold.support.GuiScript<LoginGUIData> {
	override function init(self:LoginGUIData) {
		Msg.post(".", GoMessages.acquire_input_focus);

		Gui.set_text(Gui.get_node("email/content"), "adam@enge.me");
		Gui.set_text(Gui.get_node("password/content"), "asdfasdf");
	}

	override function on_input(self:LoginGUIData, action_id:Hash, action:ScriptOnInputAction):Bool {
		// bind inputs
		self.email = DirtyLarry.input(self, "email", action_id, action, Gui.GuiKeyboardType.KEYBOARD_TYPE_EMAIL, "Enter your email");
		self.password = DirtyLarry.input(self, "password", action_id, action, Gui.GuiKeyboardType.KEYBOARD_TYPE_PASSWORD, "Enter your password");

		// bind buttons
		DirtyLarry.button(self, "join", action_id, action, function() {
			if (self.email == "" || self.password == "")
				return;

			Msg.post("/controller", Messages.Login, {
				email: self.email,
				password: self.password,
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
