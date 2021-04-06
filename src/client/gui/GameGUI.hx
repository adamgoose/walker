package gui;

class GameGUI extends defold.support.GuiScript<{}> {
	public static var SetScoreboard(default, never) = new Message<lua.Table<String, Int>>("set_scoreboard");

	override function init(self:{}) {
		Gui.set_enabled(Gui.get_node("w_key"), false);
		Gui.set_enabled(Gui.get_node("a_key"), false);
		Gui.set_enabled(Gui.get_node("s_key"), false);
		Gui.set_enabled(Gui.get_node("d_key"), false);
		Gui.set_enabled(Gui.get_node("scoreboard"), false);
	}

	override function on_message<T>(self:{}, message_id:Message<T>, message:T, sender:Url):Void {
		switch (message_id) {
			case Messages.Connected:
				Gui.set_color(Gui.get_node("pip"), Vmath.vector4(0, 255, 0, .5));
				Gui.set_enabled(Gui.get_node("w_key"), true);
				Gui.set_enabled(Gui.get_node("a_key"), true);
				Gui.set_enabled(Gui.get_node("s_key"), true);
				Gui.set_enabled(Gui.get_node("d_key"), true);
			case Messages.Disconnected:
				Gui.set_color(Gui.get_node("pip"), Vmath.vector4(255, 0, 0, .5));
			case Messages.SetText:
				Gui.set_text(Gui.get_node("text"), message.text);
			case SetScoreboard:
				Gui.set_enabled(Gui.get_node("scoreboard"), true);
				var text = "";
				for (user => score in lua.Table.toMap(message)) {
					text = '${user}: ${score}\n${text}';
				}
				Gui.set_text(Gui.get_node("scoreboard"), text);
		}
	}
}
