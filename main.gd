class_name Main extends Control

@onready var bananaapi: GameBananaAPI = $GameBananaAPI
@onready var line_edit: LineEdit = $LineEdit
var modsList:Array[Node] = []

var row: int = 0

@onready var MEOW: Array = $engines.get_children()
@onready var mod_container: Control = %ModContainer

static var instance: Main

func fix_window_scale() -> void:
	var scale_factor := DisplayServer.screen_get_scale()
	if scale_factor == 1.0:
		return

	var window := get_window()
	window.content_scale_factor = scale_factor
	window.size *= scale_factor
	window.move_to_center()

func _enter_tree() -> void:
	fix_window_scale()

func _ready() -> void:
	if instance == null: instance = self
	bananaapi.search_complete.connect(
		func generate_mods(data) -> void:
			var i: int = 0
			var columns: int = 2

			for test in data._aRecords:
				var mod: WideMod = preload("uid://crlo3c1jhu1es").instantiate()
				mod.name = str(test._idRow)
				mod.modData = test

				var column = i % columns
				row = i / columns

				mod.position = Vector2(
					150 + (column * 520),
					80 + (row * 320)
				)

				mod_container.add_child(mod)
				modsList.append(mod)

				i += 1
	)

func _get_hovered_item(mouse_pos: Vector2) -> Node2D:
	for bark: Sprite2D in MEOW:
		var local_mouse := bark.to_local(mouse_pos)
		var rect := Rect2(-bark.texture.get_size() / 2.0, bark.texture.get_size())
		if rect.has_point(local_mouse):
			return bark
	return null

var hover: Node

func _process(delta: float) -> void:
	hover = _get_hovered_item(get_global_mouse_position())

	if bananaapi.total > 0:
		var percentage = (bananaapi.downloaded / bananaapi.total) * 100.0

		if percentage >= 99.9:
			$downloadshit/Label.text = "Extracting"
		else:
			$downloadshit/Label.text =	"Download: %.1f%% (%s / %s)" % [
				percentage,
				String.humanize_size(floori(bananaapi.downloaded)),
				String.humanize_size(floori(bananaapi.total))
			]


var downloading: bool = false

func _input(event: InputEvent) -> void:
	if hover == null: return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not downloading:
		match hover.name:
			"psych":
				var absolute_path = ProjectSettings.globalize_path("user://")
				print(absolute_path)

				if DirAccess.dir_exists_absolute("user://PsychEngine"):
					open_exe("PsychEngine", "PsychEngine.exe")
				else:
					downloading = true
					bananaapi.download_from_github("ShadowMario", "FNF-PsychEngine", "1.0.4", "PsychEngine-Windows64.zip")

func search_mod(new_text: String) -> void:
	while not modsList.is_empty():
		modsList.pop_back().queue_free()

	modsList.clear()

	bananaapi.search_mods(new_text)

func open_exe(folder: String, exe_name: String) -> int:
	return OS.create_process("cmd.exe", ["/C", "cd /d " + ProjectSettings.globalize_path("user://") + "\\" + folder + " && .\\" + exe_name])
