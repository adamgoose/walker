import lua.PairTools;
import lua.TableTools;
import lua.Table;
import Beer;

typedef GameData = {
	var match:nakama.Match;
	var users:Map<String, User>;
	var scores:Table<String, Int>;
	var playerObj:Hash;
	var playerObjs:Map<String, Hash>;
	var beerObjs:Map<String, Hash>;
}

class Game extends defold.support.Script<GameData> {
	override function init(self:GameData) {
		self.users = new Map();
		self.playerObjs = new Map();
		self.beerObjs = new Map();
	}

	function spawnBeer(self:GameData, beer:BeerData) {
		var p = Vmath.vector3(beer.position.x, beer.position.y, beer.position.z);
		var b = self.beerObjs[beer.id] = Factory.create("#beerFactory", p, null, null, 0.75);
		Msg.post(b, Beer.SetId, {id: beer.id});
	}

	override function on_message<T>(self:GameData, message_id:Message<T>, message:T, sender:Url) {
		switch (message_id) {
			case Messages.JoinMatch:
				self.match = message.match;
				for (u in lua.PairTools.ipairsIterator(message.users)) {
					self.users[u.value.presence.session_id] = u.value;
				}

				Msg.post("/gameGui", Messages.SetText, {
					text: "Friends!",
				});

				spawnSelf(self, message.skin);
				for (player in lua.PairTools.ipairsIterator(self.match.presences))
					spawnPlayer(self, player.value);
			case Messages.OnMatchpresence:
				if (message.joins != null)
					for (player in lua.PairTools.ipairsIterator(message.joins))
						spawnPlayer(self, player.value);
				if (message.leaves != null)
					for (player in lua.PairTools.ipairsIterator(message.leaves))
						despawnPlayer(self, player.value);
			case Messages.OnMatchdata:
				switch (message.op_code) {
					case "1": // Move
						positionPlayer(self, message.presence, nakama.Json.decode(message.data));
					case "2": // SpawnBeer
						var beer:BeerData = nakama.Json.decode(message.data);
						spawnBeer(self, beer);
					case "3": // ClaimBeer
						var beer:BeerData = nakama.Json.decode(message.data);
						if (self.beerObjs[beer.id] != null) {
							Go.delete(self.beerObjs[beer.id]);
							self.beerObjs.remove(beer.id);
						}
					case "4": // Scores
						self.scores = nakama.Json.decode(message.data);
						Msg.post("/gameGui", gui.GameGUI.SetScoreboard, self.scores);
				}
			case Beer.BeerClaimed:
				// TODO: Figure out if it was me that did it...
				if (self.beerObjs[message.id] != null) {
					Msg.post(self.beerObjs[message.id], Beer.Nuke);
					self.beerObjs.remove(message.id);
				}
				Msg.post("/controller", Messages.SendMatchState, {
					match_id: self.match.match_id,
					op_code: 3,
					data: message,
				});
			case Messages.Move:
				Msg.post("/controller", Messages.SendMatchState, {
					match_id: self.match.match_id,
					op_code: 1,
					data: message,
				});
		}
	}

	function spawnSelf(self:GameData, skin:Int):Hash {
		var p = Table.create();
		p.skin = skin;
		var player = Factory.create("#playerFactory", null, null, p);
		Msg.post(player, Messages.EnableControl);
		Msg.post(player, Messages.ReportPlayerPosition);

		var u = self.users[self.match.self.session_id];
		Msg.post(player, Messages.SetText, {text: Table.toMap(u.string_properties)["username"]});

		return self.playerObj = player;
	}

	function get<T>(t:Table<String, T>, k:String):T {
		return Table.toMap(t)[k];
	}

	function spawnPlayer(self:GameData, presence:nakama.Presence):Hash {
		if (self.playerObjs.exists(presence.session_id) || (self.match != null && presence.session_id == self.match.self.session_id))
			return null;

		var u = self.users[presence.session_id];
		var p = Table.create();
		p.skin = Table.toMap(u.numeric_properties)["skin"];
		var player = Factory.create("#playerFactory", null, null, p);
		Msg.post(player, Messages.SetText, {
			text: Table.toMap(u.string_properties)["username"],
		});

		return self.playerObjs[presence.session_id] = player;
	}

	function positionPlayer(self:GameData, presence:nakama.Presence, move:Messages.MoveCmd):Void {
		var p = self.playerObjs[presence.session_id];
		if (p != null)
			Msg.post(p, Messages.Move, move);
	}

	function despawnPlayer(self:GameData, presence:nakama.Presence):Void {
		Go.delete(self.playerObjs[presence.session_id]);
		self.playerObjs.remove(presence.session_id);

		// If no players, disconnect?
	}
}
