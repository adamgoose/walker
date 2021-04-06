package nakama;

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

typedef Socket = {
	var config:Client;
	var scheme:String;
};

typedef Presences = lua.Table<Int, Presence>;

typedef Match = {
	var match_id:String;
	var self:Presence;
	var presences:Presences;
};

typedef Presence = {
	var user_id:String;
	var session_id:String;
	var username:String;
}

typedef MatchPresenceEvent = {
	var joins:Presences;
	var leaves:Presences;
}

typedef MatchDataEvent = {
	var presence:Presence;
	var op_code:String;
	var data:String;
}

typedef Matchmakermatched = {
	var match_id:String;
	var ticket:String;
	var token:String;
	var self:User;
	var users:lua.Table<Int, User>;
}

typedef User = {
	var string_properties:lua.Table<String, String>;
	var numeric_properties:lua.Table<String, Float>;
	var presence:Presence;
}
