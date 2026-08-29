class_name WideMod extends Control

var imageURL: String = ""
var modData

func _ready() -> void:
	%ModName.text = modData._sName

	var t = get_tree().create_timer(0.25, false)
	await t.timeout

	var http = HTTPRequest.new()
	http.set_tls_options(TLSOptions.client_unsafe())
	add_child(http)

	http.request_completed.connect(_on_image_loaded)

	var url = modData._aPreviewMedia._aImages[0]._sBaseUrl + "/" + modData._aPreviewMedia._aImages[0]._sFile
	http.request(url)

@export var bg_image: Control

func _get_hovered_item() -> Control:
	var rect := bg_image.get_global_rect()
	if rect.has_point(get_global_mouse_position()):
		return bg_image
	else:
		return null

var hover: Node

func _process(_delta: float) -> void:
	hover = _get_hovered_item()

func _input(event: InputEvent) -> void:
	if hover == null: return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_ancestor_of(hover):
			Main.instance.bananaapi.download_from_gamebanana(str(int(modData._idRow)))

func _on_image_loaded(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		print("Request failed! Result: ", result)
		return

	var image = Image.new()
	var error = image.load_jpg_from_buffer(body)

	if error != OK:
		print("Failed to load JPG! Error: ", error)
		return

	var texture = ImageTexture.create_from_image(image)
	bg_image.texture = texture
