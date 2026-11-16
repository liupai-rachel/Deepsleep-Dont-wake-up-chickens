class_name ArcadeDifficulty
extends RefCounted

static func for_stage(map_index: int, room: int) -> Dictionary:
	# Each chapter starts easier than the previous finale, then rises again.
	var pressure := (clampi(map_index,1,4)-1)*0.65+(clampi(room,1,4)-1)*0.60
	var scale := 1.0+(room-1)*0.2
	return {"pressure":pressure,"animals":3+room+(map_index-1)/2,
		"patrol_speed":(82.0+pressure*9.0)*scale,"vision":(140.0+pressure*5.0)*scale,"vision_angle":54.0+pressure*1.6,
		"sight_gain":9.0+pressure*4.5,"cluck_gain":13.0+pressure*2.0,
		"calm_delay":2.5+pressure*0.3,"decay":9.0-pressure*1.1,
		"summon_at":100.0,"warning":1.8-pressure*0.16,
		"farmer_chase":185.0+pressure*10.0,"farmer_walk":145.0+pressure*6.0,
		"farmer_vision":(220.0+pressure*12.0)*scale,"farmer_search":3.0}
