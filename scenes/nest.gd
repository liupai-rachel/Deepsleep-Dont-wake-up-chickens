class_name CoopNest
extends Node2D

enum Status { UNSEARCHED, SEARCHABLE, EMPTY }

const MIN_EGGS := 1
const MAX_EGGS := 3

@export_range(1.0, 200.0, 1.0) var interaction_radius := 44.0

var eggs_left := 0
var status := Status.UNSEARCHED

@onready var _straw: Sprite2D = $Straw
@onready var _status_mark: Label = $StatusMark


func set_initial_stock(stock: int) -> void:
	eggs_left = stock


func take_egg() -> bool:
	if eggs_left <= 0:
		return false
	eggs_left -= 1
	if eggs_left == 0:
		status = Status.EMPTY
		_straw.modulate = Color(0.58, 0.52, 0.45)
		_status_mark.text = "X"
	else:
		status = Status.SEARCHABLE
		_straw.modulate = Color(1.0, 0.9, 0.67)
		_status_mark.text = "+"
	return true


func set_targeted(targeted: bool) -> void:
	$Highlight.visible = targeted
