import defold.support.Script;
import defold.support.ScriptOnInputAction;
import defold.Sprite;

typedef PlayerData = {
	@property(0) var skin:Int;

	var state:String;
	var dirY:String;
	var dirX:String;
	var animation:String;
	var sprinting:Bool;
	var speed:Vector3;
	var controlled:Bool;
	var reportPlayerPosition:Bool;
}

class Player extends defold.support.Script<PlayerData> {
	var walkSpeed = 150;
	var sprintSpeed = 300;
	var maxX = 1280;
	var maxY = 720;

	override function init(self:PlayerData) {
		self.state = "idle";
		self.dirY = "s";
		self.speed = Vmath.vector3();
	}

	override function update(self:PlayerData, dt) {
		if (!self.controlled)
			return;

		// Set Initial Animation
		if (self.animation == "" && self.skin != 0) {
			self.animation = '${self.skin}_idle_s';
			Msg.post("#sprite", SpriteMessages.play_animation, {
				id: hash(self.animation),
			});
		}

		// Remember Stuff
		var oldState = self.state;
		var oldDirX = self.dirX;
		var oldDirY = self.dirY;

		// Update Stuff
		updatePosition(self, dt);
		updateVisuals(self);
		reportPosition(self);

		// Conditionally update animation
		if ((self.dirX != oldDirX) || (self.dirY != oldDirY) || (self.state != oldState))
			Msg.post("#sprite", SpriteMessages.play_animation, {
				id: hash(self.animation),
			});

		// Clean Up
		self.speed = Vmath.vector3();
	}

	override function on_input(self:PlayerData, action_id:Hash, action:ScriptOnInputAction):Bool {
		if (action_id == hash("sprint")) {
			self.sprinting = !action.released;
		} else {
			var speed = self.sprinting ? sprintSpeed : walkSpeed;
			if (action_id == hash("n")) {
				self.speed.y += speed;
			} else if (action_id == hash("s")) {
				self.speed.y -= speed;
			} else if (action_id == hash("e")) {
				self.speed.x += speed;
			} else if (action_id == hash("w")) {
				self.speed.x -= speed;
			}
		}

		return true;
	}

	override function on_message<T>(self:PlayerData, message_id:Message<T>, message:T, sender:Url) {
		switch (message_id) {
			case Messages.EnableControl:
				self.controlled = true;
				Msg.post(".", GoMessages.acquire_input_focus);
			case Messages.ReportPlayerPosition:
				self.reportPlayerPosition = true;
			case Messages.SetText:
				Label.set_text("#email", message.text);
			case Messages.Move:
				move(self, message.skin, message.animation, message.position);
		}
	}

	function updatePosition(self:PlayerData, dt) {
		var p = Go.get_position();

		// cap position
		p.y = Math.max(0, Math.min(maxY, p.y));
		p.x = Math.max(0, Math.min(maxX, p.x));

		// move
		p += self.speed * dt;
		Go.set_position(p);
	}

	function reportPosition(self:PlayerData) {
		if (self.reportPlayerPosition) {
			Msg.post("/game", Messages.Move, {
				skin: self.skin,
				animation: self.animation,
				position: Go.get_position(),
			});
		}
	}

	function updateVisuals(self:PlayerData) {
		self.state = (self.speed == Vmath.vector3()) ? 'idle' : 'walk';

		switch self.speed.x {
			case _ > 0 => true:
				self.dirX = 'e';
			case _ < 0 => true:
				self.dirX = 'w';
			case self.speed != Vmath.vector3() => true:
				self.dirX = '';
			case _:
		}

		switch self.speed.y {
			case _ > 0 => true:
				self.dirY = 'n';
			case _ < 0 => true:
				self.dirY = 's';
			case self.speed != Vmath.vector3() => true:
				self.dirY = '';
			case _:
		}

		self.animation = '${self.skin}_${self.state}_${self.dirY}${self.dirX}';
	}

	function move(self:PlayerData, skin:Int, animation:String, position:Vector3) {
		self.skin = skin;

		// set position
		var p = Vmath.vector3(position.x, position.y, position.z);
		Go.set_position(p);

		// conditionally play animation
		if (animation != self.animation) {
			self.animation = animation;
			Msg.post("#sprite", SpriteMessages.play_animation, {
				id: hash(self.animation),
			});
		}
	}
}
