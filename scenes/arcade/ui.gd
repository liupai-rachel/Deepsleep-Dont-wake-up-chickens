class_name ArcadeUI
extends CanvasLayer

signal start_requested(level: int)
signal upgrade_requested(index: int)
signal pause_requested
signal abandon_requested
signal selection_changed(level: int)

const FONT := preload("res://assets/fonts/CoopUI.ttf")
const PIXEL := preload("res://assets/fonts/PressStart2P-Regular.ttf")
const STAGE_ZH := ["小鸡舍", "鸡舍院落", "扩建农场", "大型农场"]
const STAGE_EN := ["Coop", "Yard", "Farm", "Estate"]
var language := "zh"
var screen: Control
var overlay: ColorRect
var score_label: Label
var egg_label: Label
var time_label: Label
var combo_label: Label
var stage_label: Label
var hint: Label
var toast: Label
var combo_bar: ProgressBar
var pause_button: Button
var round_duration := 120
var _toast_left := 0.0
var _profile: ArcadeProfile
var _selected := 1
var _result := {}
var _paused := false
var _running := false

func tr2(zh: String, en: String) -> String:
	return en if language == "en" else zh

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	screen = Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme := Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 16
	screen.theme = theme
	add_child(screen)
	var frames := Control.new()
	frames.set_script(preload("res://scenes/hud_frames.gd"))
	frames.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(frames)
	score_label = _label(screen,Rect2(47,11,137,31),"",17)
	time_label = _label(screen,Rect2(832,11,106,31),"2:00",18)
	combo_label = _label(screen,Rect2(387,14,186,20),"",14)
	egg_label = _label(screen,Rect2(22,499,140,29),"",15)
	stage_label = _label(screen,Rect2(785,499,154,29),"",14)
	hint = _label(screen,Rect2(231,499,500,29),"",14)
	combo_bar = ProgressBar.new()
	combo_bar.position = Vector2(385,38)
	combo_bar.size = Vector2(190,5)
	combo_bar.max_value = 2.2
	combo_bar.show_percentage = false
	combo_bar.add_theme_font_size_override("font_size",1)
	combo_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combo_bar.add_theme_stylebox_override("fill",_style(Color("efba55"),Color("efba55"),0))
	combo_bar.add_theme_stylebox_override("background",_style(Color("0c1326"),Color("453520"),0))
	screen.add_child(combo_bar)
	combo_bar.size = Vector2(190,5)
	toast = _label(screen,Rect2(200,63,560,30),"",17)
	toast.add_theme_color_override("font_outline_color",Color("172033"))
	toast.add_theme_constant_override("outline_size",4)
	pause_button = _button(screen,Rect2(852,48,91,25),"Esc",func(): pause_requested.emit())
	pause_button.add_theme_font_size_override("font_size",13)
	overlay = ColorRect.new()
	overlay.color = Color(0.015,0.025,0.055,0.84)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(overlay)

func _style(background: Color, border := Color("bd914b"), width := 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.set_border_width_all(width)
	style.border_color = border
	style.content_margin_left = 8
	style.content_margin_right = 8
	return style

func _label(parent: Node, rect: Rect2, text: String, font_size := 16) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("ffe5ad"))
	parent.add_child(label)
	return label

func _button(parent: Node, rect: Rect2, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.text = text
	button.add_theme_stylebox_override("normal",_style(Color("202237")))
	button.add_theme_stylebox_override("hover",_style(Color("594126"),Color("ffe19b"),2))
	button.add_theme_stylebox_override("pressed",_style(Color("7b592d"),Color("ffe19b"),2))
	button.add_theme_stylebox_override("disabled",_style(Color("111725"),Color("343744")))
	button.add_theme_stylebox_override("focus",_style(Color(0,0,0,0),Color("fff0b0"),2))
	button.add_theme_font_size_override("font_size",15)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _process(delta: float) -> void:
	_toast_left = maxf(0.0,_toast_left-delta)
	toast.visible = _toast_left > 0.0 and not overlay.visible

func announce(zh: String, en: String) -> void:
	toast.text = tr2(zh,en)
	_toast_left = 3.0

func update_game(score: int, eggs: int, chain: int, multiplier: int, combo_left: float, seconds: float, level: int) -> void:
	score_label.text = tr2("得分 %d","Score %d") % score
	egg_label.text = tr2("鸡蛋 %d","Eggs %d") % eggs
	time_label.text = "%d:%02d" % [ceili(seconds)/60,ceili(seconds)%60]
	combo_label.text = tr2("连捡 %d  ×%d","Chain %d  x%d") % [chain,multiplier] if chain > 0 else tr2("右键开始收集","Right-click to collect")
	combo_bar.value = combo_left
	stage_label.text = ("%d · " % level) + (STAGE_EN if language == "en" else STAGE_ZH)[level-1]
	hint.text = tr2("右键捡蛋 / 连点鸡窝　 WASD 移动","Right-click eggs / nests   WASD move")

func show_menu(profile: ArcadeProfile, selected: int, result := {}, paused := false) -> void:
	_profile = profile
	_selected = selected
	_result = result
	_paused = paused
	_running = paused
	for child in overlay.get_children():
		overlay.remove_child(child)
		child.queue_free()
	overlay.show()
	pause_button.hide()
	var panel := Panel.new()
	panel.position = Vector2(102,42)
	panel.size = Vector2(756,456)
	panel.add_theme_stylebox_override("panel",_style(Color("0b1224"),Color("d3a859"),2))
	overlay.add_child(panel)
	var title := tr2("夜访鸡舍 · 捡蛋冲分","NIGHT COOP: EGG RUSH")
	if paused: title = tr2("休息一下","PAUSED")
	elif not result.is_empty(): title = tr2("本局收获","ROUND COMPLETE")
	_label(panel,Rect2(20,14,716,41),title,28 if language == "zh" else 25)
	var summary := tr2("右键点击蛋或鸡窝，鸡蛋立即飞入背包；靠近不会自动捡。","Right-click an egg or nest to collect. Walking near eggs does not collect them.")
	if not result.is_empty():
		summary = tr2("得分 %d　鸡蛋 %d　奖励 %d 币　%s","Score %d   Eggs %d   +%d coins   %s") % [result.score,result.get("eggs",0),result.reward,tr2("新纪录！","NEW BEST!") if result.record else ""]
	_label(panel,Rect2(15,60,726,28),summary,15)
	_label(panel,Rect2(18,91,720,24),tr2("选择关卡 · 完成一局即可解锁下一关","CHOOSE A STAGE · Finish a round to unlock the next"),15)
	for i in range(4):
		var level := i+1
		var name: String = (STAGE_EN if language == "en" else STAGE_ZH)[i]
		var text := "%d  %s" % [level,name]
		if level > profile.unlocked: text += tr2("\n未解锁","\nLocked")
		elif level == selected: text += tr2("\n已选择","\nSelected")
		var button := _button(panel,Rect2(24+i*180,120,168,54),text,func(): selection_changed.emit(level))
		button.disabled = paused or level > profile.unlocked
		if level == selected: button.add_theme_stylebox_override("normal",_style(Color("584127"),Color("ffe0a0"),2))
	_label(panel,Rect2(18,182,720,24),tr2("钱币 %d　｜　本关最高分 %d","Coins %d   |   Stage best %d") % [profile.coins,profile.best[selected-1]],17)
	var names := [tr2("连收范围","Gather radius"),tr2("额外收获","Bonus eggs"),tr2("鸡窝补货","Nest refill")]
	var details := [tr2("一次右键收集附近更多蛋","One click gathers nearby eggs"),tr2("每级增加 10%% 双份概率","+10%% chance of an extra egg / level"),tr2("缩短空鸡窝的补货间隔","Empty nests refill sooner")]
	for i in range(3):
		var index := i
		var price := profile.cost(i)
		_label(panel,Rect2(20+i*240,215,236,24),"%s  Lv.%d" % [names[i],profile.upgrades[i]],17)
		_label(panel,Rect2(20+i*240,241,236,25),details[i].replace("%%","%"),12)
		var text := tr2("已满级","MAX LEVEL") if price < 0 else tr2("升级 · %d 币","Upgrade · %d coins") % price
		var button := _button(panel,Rect2(30+i*240,274,216,35),text,func(): upgrade_requested.emit(index))
		button.disabled = paused or price < 0 or profile.coins < price
	var guide := tr2("WASD 移动 · 右键拾取 · Esc 暂停\n鸡窝里的蛋数直接可见；第 3、4 关后半程出现黄金鸡。","WASD move · Right-click collect · Esc pause\nVisible nest stocks. Golden hens arrive in stages 3–4 after halfway.")
	_label(panel,Rect2(18,319,720,43),guide,14)
	if not profile.saved:
		_label(panel,Rect2(18,361,720,20),tr2("当前浏览器无法保存进度，关闭后升级可能丢失。","Storage is unavailable; upgrades may be lost when this tab closes."),12)
	var primary := _button(panel,Rect2(24,389,490,44),tr2("继续游戏","Resume") if paused else tr2("开始第 %d 关 · %d 秒","Play stage %d · %d seconds") % [selected,round_duration],func():
		if _paused: pause_requested.emit()
		else: start_requested.emit(_selected))
	primary.add_theme_stylebox_override("normal",_style(Color("6e4d24"),Color("ffe0a0"),2))
	_button(panel,Rect2(530,389,95,44),"中文" if language == "en" else "English",func():
		language = "zh" if language == "en" else "en"
		show_menu(_profile,_selected,_result,_paused))
	if paused:
		_button(panel,Rect2(640,389,92,44),tr2("回菜单","Menu"),func(): abandon_requested.emit())
	else:
		_label(panel,Rect2(640,389,92,44),tr2("每 5 分\n换 1 币","5 points\n= 1 coin"),13)
	primary.grab_focus()

func hide_menu() -> void:
	overlay.hide()
	pause_button.show()
