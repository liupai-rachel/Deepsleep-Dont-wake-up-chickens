class_name ArcadeDifficulty
extends RefCounted

static func for_stage(map_index: int, room: int) -> Dictionary:
	# Each chapter starts easier than the previous finale, then rises again.
	var pressure := (clampi(map_index,1,4)-1)*0.65+(clampi(room,1,4)-1)*0.60
	var scale := 1.0+(room-1)*0.2
	return {"pressure":pressure,"animals":3+room+(map_index-1)/2,
		"patrol_speed":(82.0+pressure*9.0)*scale,"vision":(175.0+pressure*15.0)*scale,
		"sight_gain":9.0+pressure*4.5,"cluck_gain":13.0+pressure*2.0,
		"calm_delay":2.5+pressure*0.3,"decay":9.0-pressure*1.1,
		"summon_at":60.0-pressure*3.5,"warning":1.8-pressure*0.16,
		"farmer_chase":270.0+pressure*20.0,"farmer_walk":205.0+pressure*12.0,
		"farmer_vision":(240.0+pressure*20.0)*scale,"farmer_search":3.5+pressure*0.5}
