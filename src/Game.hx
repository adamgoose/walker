import lua.Table;

typedef GameData = {
	var match:nakama.Match;
	var player:Hash;
	var players:Map<String, Hash>; // TODO
}

class Game extends defold.support.Script<GameData> {
	override function init(self:GameData) {
		self.players = new Map();
	}

	override function on_message<T>(self:GameData, message_id:Message<T>, message:T, sender:Url) {
		switch (message_id) {
			case Messages.JoinMatch:
				self.match = message.match;
				Msg.post("/gameGui", Messages.SetText, {
					text: "Friends!",
				});

				spawnSelf(self, message.skin, self.match.self.username);
				for (player in lua.PairTools.ipairsIterator(self.match.presences))
					spawnPlayer(self, player.value);
			case Messages.OnMatchpresence:
				for (player in lua.PairTools.ipairsIterator(message.joins))
					spawnPlayer(self, player.value);
				for (player in lua.PairTools.ipairsIterator(message.leaves))
					despawnPlayer(self, player.value);
			case Messages.OnMatchdata:
				switch (message.op_code) {
					case "1":
						positionPlayer(self, message.presence, nakama.Json.decode(message.data));
				}
			case Messages.Move:
				Msg.post("/controller", Messages.SendMatchState, {
					match_id: self.match.match_id,
					op_code: 1,
					data: message,
				});
		}
	}

	function spawnSelf(self:GameData, skin:Int, text:String):Hash {
		var p = Table.create();
		p.skin = skin;
		var player = Factory.create("#playerFactory", null, null, p);
		Msg.post(player, Messages.EnableControl);
		Msg.post(player, Messages.ReportPlayerPosition);
		Msg.post(player, Messages.SetText, {text: text});

		return self.player = player;
	}

	function spawnPlayer(self:GameData, presence:nakama.Presence):Hash {
		if (self.players.exists(presence.session_id) || presence.session_id == self.match.self.session_id)
			return null;

		var player = Factory.create("#playerFactory");
		Msg.post(player, Messages.SetText, {
			text: presence.username,
		});

		return self.players[presence.session_id] = player;
	}

	function positionPlayer(self:GameData, presence:nakama.Presence, move:Messages.MoveCmd):Void {
		var p = self.players[presence.session_id];
		if (p != null)
			Msg.post(p, Messages.Move, move);
	}

	function despawnPlayer(self:GameData, presence:nakama.Presence):Void {
		Go.delete(self.players[presence.session_id]);
		self.players.remove(presence.session_id);

		// If no players, disconnect?
	}
}
