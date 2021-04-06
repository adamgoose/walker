package nakama;

import nakama.Types;

class MatchHandler<T:Dynamic> {
	// match_init(context, params) -> state, tickrate, label
	function match_init(context:MatchContext, ?params:Dynamic):MatchInitRt<T> {
		return new MatchInitRt<T>(({} : Dynamic), 1, "");
	}

	// match_join_attempt(context, dispatcher, tick, state, presence, metadata) -> state, accepted, reject_reason
	function match_join_attempt(context:MatchContext, dispatcher:{}, tick:Int, state:T, presence:Presence, metadata:{}):MatchJoinAttemptRt<T> {
		return new MatchJoinAttemptRt<T>(state, true, "");
	}

	// match_join(context, dispatcher, tick, state, presences) -> state
	function match_join(context:MatchContext, dispatcher:{}, tick:Int, state:T, presences:Presences):T {
		return state;
	}

	// match_leave(context, dispatcher, tick, state, presences) -> state
	function match_leave(context:MatchContext, dispatcher:{}, tick:Int, state:T, presences:Presences):T {
		return state;
	}

	// match_loop(context, dispatcher, tick, state, messages) -> state
	function match_loop(context:MatchContext, dispatcher:{}, tick:Int, state:T, messages:{}):T {
		return state;
	}

	// match_terminate(context, dispatcher, tick, state, grace_seconds) -> state
	function match_terminate(context:MatchContext, dispatcher:Int, tick:{}, state:T, grace_seconds:{}):T {
		return state;
	}
}

class MatchInitRt<T> {
	public function new(state:T, tickrate:Int, label:String) {
		this.state = state;
		this.tickrate = tickrate;
		this.label = label;
	}

	var state:T;
	var tickrate:Int;
	var label:String;
}

class MatchJoinAttemptRt<T> {
	public function new(state:T, accepted:Bool, reject_reason:String) {
		this.state = state;
		this.accepted = accepted;
		this.reject_reason = reject_reason;
	}

	var state:T;
	var accepted:Bool;
	var reject_reason:String;
}

typedef MatchContext = {
	var env:Map<String, String>;
	var execution_mode:String;
	var query_params:Map<String, String>;
	var session_id:String;
	var user_id:String;
	var username:String;
	var user_session_exp:Int;
	var client_ip:String;
	var client_port:String;
	var match_id:String;
	var match_node:String;
	var match_label:String;
	var match_tick_rate:Int;
};
