class_name ArcadeFarmer
extends CoopFarmer

signal player_lost
var forget_seconds := 3.0
var unseen_seconds := 0.0
var leaving := false
var _leave_seconds := 0.0

func _physics_process(delta: float) -> void:
	if leaving:
		# Once the search ends, leaving farmers cannot reacquire or catch the player.
		sees_player = false
		state = State.RETREATING
		_leave_seconds += delta
		var previous := position
		var arrived := _walk_to(home_position,walk_speed,delta)
		_body.modulate = Color(0.8,0.85,0.9,clampf((8.0-_leave_seconds)/0.4,0.0,1.0))
		_body.update_pose(_facing,position.distance_squared_to(previous) > 0.001,&"idle",delta)
		if arrived or _leave_seconds >= 8.0:
			set_physics_process(false)
			departed.emit()
		return
	super._physics_process(delta)
	if not is_physics_processing(): return
	unseen_seconds = 0.0 if sees_player else unseen_seconds+delta
	if unseen_seconds >= forget_seconds:
		leaving = true
		state = State.RETREATING
		sees_player = false
		player_lost.emit()
