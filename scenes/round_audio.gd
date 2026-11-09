class_name CoopRoundAudio
extends Node

var _closing := false


func _ready() -> void:
	var tree := get_tree()
	tree.auto_accept_quit = false
	tree.root.close_requested.connect(_on_close_requested)


func play_cue(cue: StringName) -> void:
	var stream: AudioStreamPlayer = get_node(NodePath(cue))
	stream.play()


func stop_all() -> void:
	for stream: AudioStreamPlayer in get_children():
		stream.stop()


func _on_close_requested() -> void:
	if _closing:
		return
	_closing = true
	stop_all()
	var tree := get_tree()
	tree.paused = true
	# Give the audio mixer time to release its playbacks before Godot shuts down.
	tree.create_timer(0.15, true, false, true).timeout.connect(tree.quit)
