extends CharacterBody2D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var new_position: Vector2
var move_speed 
var jump_velocity

func _ready():
	new_position = position
	move_speed = get_viewport().get_visible_rect().size.x/6
	jump_velocity = get_viewport().get_visible_rect().size.y
	print("Loading finished " + str(Time.get_ticks_msec()))

func _process(delta):
	if Input.is_action_just_pressed("left_click"):
		new_position = get_global_mouse_position()
		var unix_time: float = Time.get_unix_time_from_system()
		var unix_time_int: int = unix_time
		var datetime_dict: Dictionary = Time.get_datetime_dict_from_unix_time(unix_time)
		var ms: int = (unix_time - unix_time_int) * 1000.0
		print("Input registered %02d:%02d:%02d.%03d" % [datetime_dict.hour, datetime_dict.minute,datetime_dict.second,ms])

func _physics_process(delta):
	if position.x != new_position.x:
		velocity.x = (new_position.x - position.x) * move_speed * delta
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y -= jump_velocity
	move_and_slide()
