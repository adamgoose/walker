import defold.support.Script;
import defold.support.ScriptOnInputAction;
import defold.Sprite;
import defold.Factory;
import nakama.Nakama;
import nakama.Types;
import lua.Math;
import lua.Table;

typedef ControllerData = {
	var client:Client;
	var socket:Socket;

	var username:String;
	var ticket:String;
	var toy:Hash;
	var skin:Int;
};

class Controller extends defold.support.Script<ControllerData> {
	override function init(self:ControllerData) {
		self.client = Nakama.create_client({
			host: "nakama.enge.me",
			port: 443,
			use_ssl: true,
			// host: "127.0.0.1",
			// port: 7350,
			// use_ssl: false,
			username: "defaultkey",
			password: "",
			engine: DefoldEngine,
		});
		self.socket = Nakama.create_socket(self.client);

		// seed randomizer
		Math.randomseed(lua.Os.time() * 1000);

		// pick skin
		self.skin = Std.int(Math.random(5));
		Msg.post("/mainMenu#sprite", SpriteMessages.play_animation, {
			id: hash('${self.skin}_walk_sw'),
		});

		// disable /game
		Msg.post("/game", GoMessages.disable);

		// subscribe to Nakama events
		Nakama.on_matchdata(self.socket, function(message:Dynamic):Void {
			Msg.post("/game", Messages.OnMatchdata, message.match_data);
		});
		Nakama.on_matchpresence(self.socket, function(message:Dynamic):Void {
			Msg.post("/game", Messages.OnMatchpresence, message.match_presence_event);
		});
		Nakama.on_matchmakermatched(self.socket, function(message:Dynamic):Void {
			onMatchmakermatched(self, message.matchmaker_matched);
		});
	}

	override function on_message<T>(self:ControllerData, message_id:Message<T>, message:T, sender:Url) {
		switch message_id {
			case Messages.Login:
				Nakama.sync(function() {
					handleLogin(self, message);
				});
			case Messages.SocketSend:
				Nakama.sync(function() {
					Nakama.socket_send(self.socket, message);
				});
			case Messages.SendMatchState:
				Nakama.sync(function() {
					var data = haxe.Json.stringify(message.data, function(key:Dynamic, value:Dynamic):Dynamic {
						if (key == "position") {
							return {x: value.x, y: value.y, z: value.z};
						}
						return value;
					});
					var req = Nakama.create_match_data_message(message.match_id, message.op_code, data);
					Nakama.socket_send(self.socket, req);
				});
			case Messages.IncrementSkin:
				if (++self.skin > 5)
					self.skin = 1;
				Msg.post("/mainMenu#sprite", SpriteMessages.play_animation, {
					id: hash('${self.skin}_walk_sw'),
				});
		}
	}

	function handleLogin(self:ControllerData, cmd:Messages.LoginCmd) {
		// Authenticate
		var req = Nakama.create_api_account_device(DefoldEngine.uuid());
		var resp = Nakama.authenticate_device(self.client, req, true);
		// var req = Nakama.create_api_account_email(cmd.email, cmd.password);
		// var resp = Nakama.authenticate_email(self.client, req, true, cmd.username);
		if (resp.error) {
			Msg.post("/gameGui", Messages.SetText, {
				text: resp.message,
			});
			return;
		}

		// Connect
		self.username = cmd.username;
		Nakama.set_bearer_token(self.client, resp.token);
		var ok = Nakama.socket_connect(self.socket);
		if (!ok.ok) {
			pprint(ok);
		}

		// Update UI
		Msg.post("/mainMenu", GoMessages.disable);
		Msg.post("/gameGui", Messages.Connected);

		// Spawn Toy
		self.toy = spawnToy(self);

		// Begin Matchmaking
		self.ticket = beginMatchmaking(self);
	}

	function beginMatchmaking(self:ControllerData):String {
		Msg.post("/gameGui", Messages.SetText, {
			text: "Looking for friends...",
		});

		var sProps = Table.create();
		sProps.username = self.username;
		var nProps = Table.create();
		nProps.skin = self.skin / 1;
		var req = Nakama.create_matchmaker_add_message("*", 2, 10, sProps, nProps);
		var ticket = Nakama.socket_send(self.socket, req);

		return ticket.matchmaker_ticket.ticket;
	}

	function spawnToy(self:ControllerData):Hash {
		var p = Table.create();
		p.skin = self.skin;
		var toy = Factory.create("#playerFactory", null, null, p);
		Msg.post(toy, Messages.EnableControl);
		Msg.post(toy, Messages.SetText, {
			text: self.username,
		});

		return toy;
	}

	function onMatchmakermatched(self:ControllerData, message:nakama.Matchmakermatched):Void {
		if (message.ticket != self.ticket)
			return;

		self.ticket = null;

		Msg.post("/gameGui", Messages.SetText, {
			text: "Connecting to friends!",
		});
		Nakama.sync(function() {
			var req = Nakama.create_match_join_message(message.match_id, message.token);
			var match:Messages.JoinMatchCmd = Nakama.socket_send(self.socket, req);
			match.skin = self.skin;
			match.users = message.users;

			Go.delete(self.toy);
			Msg.post("/game", Messages.JoinMatch, match);
		});
	}
}
