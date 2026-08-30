class_name GameBananaAPI extends Node

const API_URL := "https://gamebanana.com/apiv11/Game/8694/"
signal search_complete

func search_mods(search_term: String):
	var http := HTTPRequest.new()
	add_child(http)

	http.request_completed.connect(_on_search_completed)

	var url = API_URL + 'Subfeed?_nPage=1&_csvModelInclusions=Mod&_sName=' + search_term.uri_encode()

	print("Searching GameBanana: ", search_term.uri_encode())

	http.request(url)

func _on_search_completed(
	result: int,
	response_code: int,
	headers: PackedStringArray,
	body: PackedByteArray
):
	if response_code != 200:
		print("GameBanana API error: ", response_code)
		return

	var data = JSON.parse_string(body.get_string_from_utf8())

	if data == null:
		print("Failed to parse JSON")
		return

	# print(data)
	search_complete.emit(data)

var zip_path: String = "user://psych-engine.zip"
var extract_dir: String = "user://"

var file_request: HTTPRequest
var download_size: int = 0
var downloaded: float = 0.0
var total: float = 0.0


func download_from_github(owner: String, repo: String, tag: String, package_name: String) -> void:
	var url = "https://github.com/%s/%s/releases/download/%s/%s" % [owner, repo, tag, package_name]
	file_request = HTTPRequest.new()
	add_child(file_request)

	file_request.set_download_file(zip_path)
	file_request.request_completed.connect(_on_download_completed)
	file_request.request(url)

func download_from_gamebanana(id: String) -> void:
	# https://gamebanana.com/apiv11/Mod/id/DownloadPage
	var download_links = HTTPRequest.new()
	download_links.set_tls_options(TLSOptions.client())
	add_child(download_links)

	download_links.request_completed.connect(
		func download_links_gotten(	result: int,
		response_code: int,
		headers: PackedStringArray,
		body: PackedByteArray
		) -> void:
			if response_code != 200:
				print("GameBanana API error: ", response_code)
				return

			var data = JSON.parse_string(body.get_string_from_utf8())

			if data == null:
				print("Failed to parse JSON")
				return

			zip_path = "user://" + data._aFiles[0]._sFile
			extract_dir = "user://PsychEngine/mods/"

			var url = str(data._aFiles[0]._sDownloadUrl)
			print("downloading mod from path " + url)

			file_request = HTTPRequest.new()
			file_request.set_tls_options(TLSOptions.client())
			add_child(file_request)

			file_request.set_download_file(zip_path)
			file_request.request_completed.connect(_on_download_completed)
			file_request.request(url)
	)

	download_links.request("https://gamebanana.com/apiv11/Mod/" + id + "/DownloadPage")

func _process(_delta: float) -> void:
	if is_instance_valid(file_request) and file_request.get_http_client_status() == HTTPClient.STATUS_BODY:
		downloaded = file_request.get_downloaded_bytes()
		total = file_request.get_body_size()

func _on_download_completed(
	result: int,
	response_code: int,
	headers: PackedStringArray,
	body: PackedByteArray
) -> void:

	if response_code == 200 or response_code == 302:
		print("Download complete!")

		_extract_zip_file()
	else:
		print("File download failed with code: ", response_code)

	file_request.queue_free()
	file_request = null

func _extract_zip_file() -> void:
	var reader := ZIPReader.new()
	var err := reader.open(zip_path)

	if err != OK:
		print("Failed to open ZIP file. Error code: ", err)
		return

	var files := reader.get_files()

	for file_inside in files:
		var target_path = extract_dir + file_inside

		if file_inside.ends_with("/"):
			DirAccess.make_dir_recursive_absolute(target_path)
			continue

		var parent_dir = target_path.get_base_dir()

		if not DirAccess.dir_exists_absolute(parent_dir):
			DirAccess.make_dir_recursive_absolute(parent_dir)

		var file_data := reader.read_file(file_inside)
		var writer := FileAccess.open(target_path, FileAccess.WRITE)

		if writer:
			writer.store_buffer(file_data)
			writer.close()

	reader.close()

	print("Extraction complete! All files saved to: ", extract_dir)

	DirAccess.remove_absolute(zip_path)
