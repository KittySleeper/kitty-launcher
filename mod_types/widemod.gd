class_name WideMod extends Node2D

var imageURL: String = ""
var modData

func _ready() -> void:
	$mod_name.text = modData._sName
	
	var t = get_tree().create_timer(0.25, false)
	await t.timeout
		
	var http = HTTPRequest.new()
	http.set_tls_options(TLSOptions.client_unsafe())
	add_child(http)

	http.request_completed.connect(_on_image_loaded)

	var url = modData._aPreviewMedia._aImages[0]._sBaseUrl + "/" + modData._aPreviewMedia._aImages[0]._sFile
	http.request(url)
	
@onready var MEOW = [$bg]

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
	
func _input(event: InputEvent) -> void:
	if hover == null: return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		match hover.name:
			"bg":
				Main.instance.bananaapi.download_from_gamebanana(str(int(modData._idRow)))

func _on_image_loaded(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		print("Request failed! Result: ", result)
		return
	
	var image = Image.new()
	var error = image.load_jpg_from_buffer(body)
	image.resize(500, 300, Image.INTERPOLATE_LANCZOS)

	if error != OK:
		print("Failed to load JPG! Error: ", error)
		return

	var texture = ImageTexture.create_from_image(image)
	$bg.texture = texture
