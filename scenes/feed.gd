class_name CoopFeed
extends Node2D

var dropped := false
var claimed := false


func _ready() -> void:
	$Bag.visible = not dropped
	$Grain.visible = dropped
	if dropped:
		add_to_group("dropped_feed")
