typedef BeerData = {
	var id:String;
	var position:Vector3;
};

typedef BeerObjData = {
	var id:String;
}

class Beer extends defold.support.Script<BeerObjData> {
	public static var SetId(default, never) = new Message<{id:String}>("set_id");
	public static var BeerClaimed(default, never) = new Message<{id:String}>("beer_claimed");
	public static var Nuke(default, never) = new Message<Void>("nuke");

	override function on_message<T>(self:BeerObjData, message_id:Message<T>, message:T, sender:Url) {
		switch message_id {
			case SetId:
				self.id = message.id;
			case Nuke:
				Go.delete(".");
			case PhysicsMessages.collision_response:
				// Make sure we only broadcast the collision if colliding with controlled player
				var url = Msg.url(null, message.other_id, hash("player"));
				var controlled:Bool = Go.get(url, "controlled");
				if (controlled)
					Msg.post("/game", BeerClaimed, {id: self.id});
		}
	}
}
