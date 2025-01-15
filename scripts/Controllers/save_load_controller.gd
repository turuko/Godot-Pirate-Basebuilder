extends Node

var encryptor_script = preload("res://scripts/Utilities/Encryptor.cs")

var encrypt: bool = false

var take_screenshot = false
var save_name: String
var capture: Image


func _ready():
	EventBus.save_button_pressed.connect(save_game)
	EventBus.load_button_pressed.connect(load_game)


func _process(delta: float) -> void:
	if take_screenshot: 
		var canvas_layer = get_node("/root/Game/CanvasLayer") as CanvasLayer
		canvas_layer.visible = false
		await get_tree().process_frame
		capture = get_viewport().get_texture().get_image()
		#await get_tree().process_frame
		canvas_layer.visible = true
		#capture.save_png("user://SaveGames/screenshot.png")
		var save_zip = ZIPPacker.new()
		if FileAccess.file_exists("user://SaveGames/" + save_name + ".zip"):
			save_zip.open("user://SaveGames/" + save_name + ".zip", ZIPPacker.APPEND_ADDINZIP)
		else:
			save_zip.open("user://SaveGames/" + save_name + ".zip", ZIPPacker.APPEND_CREATE)
		
		save_zip.start_file("image.png")
		save_zip.write_file(capture.save_png_to_buffer())
		save_zip.close_file()
		save_zip.close()
		take_screenshot = false


func save_game(args: Array) -> void:
	
	take_screenshot = true
	
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("SaveGames"):
		dir.make_dir("SaveGames")
	
	dir = DirAccess.open("user://SaveGames")
	if args.size() == 0:
		args = ["save"]
		
	save_name = str(args[0])
	var save_zip = ZIPPacker.new()
	
	if FileAccess.file_exists(dir.get_current_dir() + "/" + str(args[0]) + ".zip"):
		OS.move_to_trash(dir.get_current_dir() + "/" + str(args[0]) + ".zip")
		
	save_zip.open(dir.get_current_dir() + "/" + str(args[0]) + ".zip", ZIPPacker.APPEND_CREATE)
		
	#var save_file = FileAccess.open(dir.get_current_dir()+"/"+str(args[0]), FileAccess.WRITE)

	var map_data = GameManager.instance.map_controller.map.save()

	var data = {}
	data["world"] = map_data

	var json = JSON.stringify(data)

	if encrypt:
		var encryptor = encryptor_script.new()
		json = encryptor.Encrypt(json)
	#save_file.store_line(json)
	save_zip.start_file("data")
	save_zip.write_file(json.to_utf8_buffer())
	save_zip.close_file()
	save_zip.close()


func load_game(args: Array) -> void:
	if args.size() == 0:
		args = ["save"]
	
	if not FileAccess.file_exists("user://SaveGames/"+str(args[0])+".zip"):
		return
	
	var save_zip = ZIPReader.new()
	save_zip.open("user://SaveGames/" + str(args[0]) + ".zip")
	
	var zip_data := save_zip.read_file("data")
	
	var json_string = zip_data.get_string_from_utf8()
	save_zip.close()
	
	#var save_file = FileAccess.open("user://SaveGames/"+str(args[0]), FileAccess.READ)
	#var json_string = save_file.get_as_text()

	if encrypt:
		var encryptor = encryptor_script.new()
		json_string = encryptor.Decrypt(json_string)

	var json = JSON.new()

	var parse_result = json.parse(json_string)
	if not parse_result == OK:
		print("JSON parse error: ", json.get_error_message(), ", at: ", json.get_error_line())
		return
	var data = json.data

	#print("Parsed Data: ", data)
	GameManager.instance.map_controller.load_world(data["world"])
	
