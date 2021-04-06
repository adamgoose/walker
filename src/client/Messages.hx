@:publicFields
class Messages {
	static var EnableControl(default, never) = new Message<Void>("enable_control");
	static var ReportPlayerPosition(default, never) = new Message<Void>("report_player_position");
	static var Move(default, never) = new Message<MoveCmd>("move");
	static var SetText(default, never) = new Message<TextCmd>("set_text");
	static var IncrementSkin(default, never) = new Message<Void>("increment_skin");
	static var Connected(default, never) = new Message<Void>("connected");
	static var Disconnected(default, never) = new Message<Void>("disconnected");
	static var Login(default, never) = new Message<LoginCmd>("login");
	static var OnMatchdata(default, never) = new Message<nakama.MatchDataEvent>("on_matchdata");
	static var OnMatchpresence(default, never) = new Message<nakama.MatchPresenceEvent>("on_matchpresence");
	static var JoinMatch(default, never) = new Message<JoinMatchCmd>("join_match");
	static var SocketSend(default, never) = new Message<Dynamic>("socket_send");
	static var SendMatchState(default, never) = new Message<MatchState>("send_match_state");
}

typedef MatchState = {
	var match_id:String;
	var op_code:Int;
	var data:Dynamic;
}

typedef LoginCmd = {
	var username:String;
};

typedef TextCmd = {
	var text:String;
}

typedef MoveCmd = {
	var skin:Int;
	var animation:String;
	var position:Vector3;
}

typedef JoinMatchCmd = {
	var skin:Int;
	var match:nakama.Match;
	var users:lua.Table<Int, nakama.User>;
}
