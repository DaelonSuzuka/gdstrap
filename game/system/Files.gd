tool
extends Node

# ******************************************************************************

func check_extension(file, ext=null) -> bool:
	if ext:
		if ext is String:
			if file.ends_with(ext):
				return true
		elif ext is Array:
			for e in ext:
				if file.ends_with(e):
					return true
	return false

# get all files in given directory with optional extension filter
func get_files(path: String, ext='') -> Array:
	var _files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin(true, true)

	var file = dir.get_next()
	while true:
		var file_path = dir.get_current_dir().plus_file(file)
		if file == "":
			break
		if ext:
			if check_extension(file, ext):
				_files.append(file_path)
		else:
			_files.append(file_path)
		file = dir.get_next()

	dir.list_dir_end()

	return _files

# get all files in given directory(and subdirectories, to a given depth) with optional extension filter
func get_all_files(path: String, ext='', max_depth:=10, _depth:=0, _files:=[]) -> Array:
	if _depth >= max_depth:
		return []

	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin(true, true)

	var file = dir.get_next()
	while file != '':
		var file_path = dir.get_current_dir().plus_file(file)
		if dir.current_is_dir():
			get_all_files(file_path, ext, max_depth, _depth + 1, _files)
		else:
			if ext:
				if check_extension(file, ext):
					_files.append(file_path)
			else:
				_files.append(file_path)
		file = dir.get_next()
	dir.list_dir_end()
	return _files

# get all files AND folders in a given directory(and subdirectories, to a given depth)
func get_all_files_and_folders(path: String, max_depth:=10, _depth:=0, _files:=[]) -> Array:
	if _depth >= max_depth:
		return []

	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin(true, true)

	var file = dir.get_next()
	while file != '':
		var file_path = dir.get_current_dir().plus_file(file)
		_files.append(file_path)
		if dir.current_is_dir():
			get_all_files_and_folders(file_path, max_depth, _depth + 1, _files)
		file = dir.get_next()
	dir.list_dir_end()
	return _files

# get all folders in a given directory(and subdirectories, to a given depth)
func get_all_folders(path: String, max_depth:=10, _depth:=0, _files:=[]) -> Array:
	if _depth >= max_depth:
		return []

	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin(true, true)

	var file = dir.get_next()
	while file != '':
		var file_path = dir.get_current_dir().plus_file(file)
		if dir.current_is_dir():
			_files.append(file_path)
			get_all_folders(file_path, max_depth, _depth + 1, _files)
		file = dir.get_next()
	dir.list_dir_end()
	return _files

# ------------------------------------------------------------------------------

var file_prefix: String

func _ready():
	if OS.has_feature("standalone"):
		file_prefix = 'user://'
	else:
		file_prefix = 'res://data/'

func _ensure_prefix(path:String, prefix:=file_prefix) -> String:
	if !path.begins_with(prefix):
		path = prefix + path
	return path

func _ensure_suffix(path:String, suffix:='.json') -> String:
	if !path.ends_with(suffix):
		path += suffix
	return path

func _ensure_directory(path:String) -> void:
	var dir = Directory.new()
	if !dir.dir_exists(path):
		dir.make_dir_recursive(path)

# ------------------------------------------------------------------------------

func save_json(file_name: String, data, auto_prefix:=true) -> void:
	if auto_prefix:
		file_name = _ensure_prefix(file_name)

	file_name = _ensure_suffix(file_name)

	_ensure_directory(file_name.get_base_dir())

	var f = File.new()
	f.open(file_name, File.WRITE)
	f.store_string(JSON.print(data, "\t"))
	f.close()

func load_json(file_name: String, default=null, auto_prefix:=true):
	var result = default

	if auto_prefix:
		file_name = _ensure_prefix(file_name)

	file_name = _ensure_suffix(file_name)

	var f = File.new()
	if f.file_exists(file_name):
		f.open(file_name, File.READ)
		var text = f.get_as_text()
		f.close()
		var json = JSON.parse(text)
		if !json.error:
			result = json.result
	return result
