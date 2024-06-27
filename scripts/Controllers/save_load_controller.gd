class_name SaveLoadController extends Node

var encryptor_script = preload("res://scripts/Utilities/Encryptor.cs")

var encrypt: bool = false

func _ready():
    EventBus.save_button_pressed.connect(save_game)
    EventBus.load_button_pressed.connect(load_game)

func save_game(args: Array) -> void:
    var dir = DirAccess.open("user://")
    if not dir.dir_exists("SaveGames"):
        dir.make_dir("SaveGames")
    
    dir = DirAccess.open("user://SaveGames")
    if args.size() == 0:
        args = ["save.p"]
    var save_file = FileAccess.open(dir.get_current_dir()+"/"+str(args[0]), FileAccess.WRITE)

    var map_data = GameManager.instance.map_controller.map.save()

    var data = {}
    data["world"] = map_data
    data["date_time"] = Time.get_datetime_dict_from_system()

    var json = JSON.stringify(data)

    if encrypt:
        var encryptor = encryptor_script.new()
        json = encryptor.Encrypt(json)
    save_file.store_line(json)


func load_game(args: Array) -> void:
    if args.size() == 0:
        args = ["save.p"]
    
    if not FileAccess.file_exists("user://SaveGames/"+str(args[0])):
        return
    
    var save_file = FileAccess.open("user://SaveGames/"+str(args[0]), FileAccess.READ)
    var json_string = save_file.get_as_text()

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
    