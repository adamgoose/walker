package nakama;

@:native("nakama")
extern class Nakama {
	// Setup
	static function create_client(config:ClientConfig):Client;
	static function create_socket(client:Client):Socket;
	static function socket_connect(socket:Socket):OK;
	static function sync(callback:() -> Void):Void;

	// Messages -- TODO: Typedef these
	static function create_api_account_email(email:String, password:String):Dynamic;
	static function create_matchmaker_add_message(query:String, minPlayers:Int, maxPlayers:Int, sProps:Dynamic<String>, nProps:Dynamic<Float>):Dynamic;
	static function create_match_data_message(matchId:String, opCode:Int, data:String):Dynamic;
	static function create_match_join_message(matchId:String, token:String):Dynamic;

	// Methods
	static function authenticate_email(client:Client, body:Dynamic, create:Bool, username:String):Dynamic;
	static function set_bearer_token(client:Client, token:String):Void;
	static function socket_send(socket:Socket, body:Dynamic):Dynamic;

	// Listeners
	static function on_matchmakermatched(socket:Socket, callback:(message:Dynamic) -> Void):Void;
	static function on_matchdata(socket:Socket, callback:(message:Dynamic) -> Void):Void;
	static function on_matchpresence(socket:Socket, callback:(message:Dynamic) -> Void):Void;
}

@:native("defold")
extern class DefoldEngine {}

@:native("json")
extern class Json {
	static function encode(raw:Dynamic):String;
	static function decode(enc:String):Dynamic;
}

@:multiReturn extern class OK {
	var ok:Bool;
	var err:Dynamic;
}

typedef ClientConfig = {
	var host:String;
	var port:Int;
	var use_ssl:Bool;
	var username:String;
	var password:String;
	var engine:Engine;
};

typedef Engine = {};
typedef Client = {};
typedef Socket = {};

typedef Match = {
	var match_id:String;
	var self:Presence;
	var presences:lua.Table<Int, Presence>;
};

typedef Presence = {
	var user_id:String;
	var session_id:String;
	var username:String;
}

typedef MatchPresenceEvent = {
	var joins:lua.Table<Int, Presence>;
	var leaves:lua.Table<Int, Presence>;
}

typedef MatchDataEvent = {
	var presence:Presence;
	var op_code:String;
	var data:String;
}
