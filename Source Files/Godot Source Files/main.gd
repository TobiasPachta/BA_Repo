extends Node2D

@onready var screen_size: Vector2 = get_viewport().get_visible_rect().size
@onready var platform_scene = preload("res://platform.tscn")


var file_writer: FileAccess
var log_file_path: String
var platform_count: int = 300
var fps_count

func _ready():
	#set log file path
	log_file_path = OS.get_user_data_dir() + "/out.txt"
	#create file writer for the whole testrun
	file_writer = FileAccess.open(log_file_path, FileAccess.WRITE)
	#write header for log file
	write_to_file("CPU_ms;RAM_mb")
	#force fps to 60
	Engine.max_fps = 60
	#spawn platforms
	spawn_platforms()


func spawn_platforms():
	var spawn_position = Vector2(50,500)
	for i in platform_count:
		spawn_position.y -= 150
		spawn_position.x += 140
		if spawn_position.x >= 605:
			spawn_position.x = 50
		var temp_plat = platform_scene.instantiate()
		temp_plat.position = spawn_position
		add_child(temp_plat)

func _process(delta):
	fps_count = 1/delta

func _physics_process(delta):
	var measurement = ""
	measurement += str(Performance.get_monitor(Performance.TIME_PROCESS) * 1000) + ";"
	measurement += str(OS.get_static_memory_usage()/(1024*1024)) + ";"
	write_to_file(measurement)


func write_to_file(text_to_write: String):
	file_writer.store_line(text_to_write)
