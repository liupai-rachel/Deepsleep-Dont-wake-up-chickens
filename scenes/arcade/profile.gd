class_name ArcadeProfile
extends RefCounted

const COSTS := [20, 40, 70, 110, 160]
var coins := 0
var active_map := 1
var unlocked_maps := 1
var unlocked := 1
var map_complete := false
var best := [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
var map_best := [0,0,0,0]
var cleared := [false,false,false,false]
var run_scores := [0,0,0,0]
var upgrades := [0,0,0]
var save_path := "user://coop-rush-v1.json"
var browser_key := "coop-rush-v1"
var saved := true

func load_progress() -> void:
	var raw := ""
	if OS.has_feature("web"):
		var result = JavaScriptBridge.eval("(()=>{try{return localStorage.getItem("+JSON.stringify(browser_key)+")||''}catch(e){return ''}})()")
		if result is String: raw = result
	elif FileAccess.file_exists(save_path): raw = FileAccess.get_file_as_string(save_path)
	if raw.is_empty(): return
	var parser := JSON.new()
	if parser.parse(raw) != OK: return
	var data = parser.data
	if not data is Dictionary: return
	var version := _safe_int(data.get("version"),0,100)
	if version != 1 and version != 2: return
	coins = _safe_int(data.get("coins"),0,100000000)
	unlocked = _safe_int(data.get("unlocked"),1,4)
	_read_array(data,"best",best,10000000)
	_read_array(data,"upgrades",upgrades,5)
	if version == 2:
		unlocked_maps = _safe_int(data.get("unlocked_maps"),1,4)
		active_map = _safe_int(data.get("active_map"),1,unlocked_maps)
		map_complete = data.get("map_complete",false) == true
		_read_array(data,"map_best",map_best,40000000)
		_read_array(data,"run_scores",run_scores,10000000)
		var values = data.get("cleared")
		if values is Array:
			for i in range(mini(values.size(),4)): cleared[i] = values[i] == true

func _read_array(data: Dictionary, key: String, target: Array, maximum: int) -> void:
	var values = data.get(key)
	if values is Array:
		for i in range(mini(values.size(),target.size())): target[i] = _safe_int(values[i],0,maximum)

func _safe_int(value: Variant, minimum: int, maximum: int) -> int:
	if not (value is int or value is float): return minimum
	if value is float and not is_finite(value): return minimum
	return clampi(int(value),minimum,maximum)

func save_progress() -> bool:
	var raw := JSON.stringify({"version":2,"coins":coins,"active_map":active_map,"unlocked_maps":unlocked_maps,"unlocked":unlocked,"map_complete":map_complete,"best":best,"map_best":map_best,"cleared":cleared,"run_scores":run_scores,"upgrades":upgrades})
	if OS.has_feature("web"):
		saved = JavaScriptBridge.eval("(()=>{try{localStorage.setItem("+JSON.stringify(browser_key)+","+JSON.stringify(raw)+");return true}catch(e){return false}})()") == true
		return saved
	var file := FileAccess.open(save_path+".tmp",FileAccess.WRITE)
	if file == null:
		saved = false
		return false
	file.store_string(raw)
	file.close()
	saved = DirAccess.rename_absolute(save_path+".tmp",save_path) == OK
	return saved

func start_map(index: int) -> bool:
	if index < 1 or index > unlocked_maps: return false
	active_map = index
	unlocked = 1
	map_complete = false
	upgrades = [0,0,0]
	run_scores = [0,0,0,0]
	# Coins are a permanent wallet. Only the map's buffs and run progress reset.
	save_progress()
	return true

func cost(index: int) -> int:
	return COSTS[upgrades[index]] if index >= 0 and index < 3 and upgrades[index] < 5 else -1

func buy(index: int) -> bool:
	var price := cost(index)
	if map_complete or price < 0 or coins < price: return false
	coins -= price
	upgrades[index] += 1
	save_progress()
	return true

func best_for(map_index: int, level: int) -> int:
	return best[(map_index-1)*4+level-1]

func settle(level: int, score: int, unlock_next := true) -> Dictionary:
	if level != unlocked or map_complete: return {}
	var reward := maxi(0,score)/5
	var index := (active_map-1)*4+level-1
	var record: bool = score > best[index]
	best[index] = maxi(best[index],score)
	coins += reward
	if unlock_next:
		run_scores[level-1] = maxi(0,score)
		if level < 4: unlocked = level+1
		else:
			map_complete = true
			cleared[active_map-1] = true
			unlocked_maps = maxi(unlocked_maps,mini(4,active_map+1))
			map_best[active_map-1] = maxi(map_best[active_map-1],int(run_scores.reduce(func(a,b): return a+b,0)))
	save_progress()
	return {"map":active_map,"level":level,"score":score,"reward":reward,"record":record,"map_complete":map_complete,"total":run_scores.reduce(func(a,b): return a+b,0)}
