extends Camera2D

@export var player_node: CharacterBody2D

func _physics_process(delta):
	global_position.y = player_node.global_position.y
