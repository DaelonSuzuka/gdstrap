tool
extends EditorPlugin

# ******************************************************************************

var panels := []
var pids = []
var settings_prefix = 'debug/multirun/'

# ******************************************************************************

func _enter_tree():
	panels.append(_add_text_button('_server_pressed', 'server'))
	panels.append(_add_text_button('_client_pressed', 'client'))
	panels.append(_add_text_button('_join_pressed', 'join'))

	_add_setting('server/number_of_windows', TYPE_INT, 3)
	_add_setting('server/window_distance', TYPE_INT, 1270)
	_add_setting('server/add_custom_args', TYPE_BOOL, true)
	_add_setting('server/first_window_args', TYPE_STRING, '--server')
	_add_setting('server/other_window_args', TYPE_STRING, '--connect')

	_add_setting('client/number_of_windows', TYPE_INT, 2)
	_add_setting('client/window_distance', TYPE_INT, 1270)
	_add_setting('client/add_custom_args', TYPE_BOOL, true)
	_add_setting('client/first_window_args', TYPE_STRING, '--connect')
	_add_setting('client/other_window_args', TYPE_STRING, '--server')

	_add_setting('join/number_of_windows', TYPE_INT, 1)
	_add_setting('join/window_distance', TYPE_INT, 1270)
	_add_setting('join/add_custom_args', TYPE_BOOL, true)
	_add_setting('join/first_window_args', TYPE_STRING, '--connect')
	_add_setting('join/other_window_args', TYPE_STRING, '')

func _exit_tree():
	_remove_panels()
	kill_pids()

# ******************************************************************************

func _server_pressed():
	var window_count: int = _get_setting('server/number_of_windows')
	var window_dist: int = _get_setting('server/window_distance')
	var add_custom_args: bool = _get_setting('server/add_custom_args')
	var first_args: String = _get_setting('server/first_window_args')
	var other_args: String = _get_setting('server/other_window_args')

	var commands = ['--position', '500,0']
	if first_args && add_custom_args:
		for arg in first_args.split(' '):
			commands.push_front(arg)

	var main_run_args = _get_setting('editor/main_run_args', false)
	if main_run_args != first_args:
		_set_setting('editor/main_run_args', first_args, false)
	var interface = get_editor_interface()
	interface.play_main_scene()
	if main_run_args != first_args:
		_set_setting('editor/main_run_args', main_run_args, false)

	kill_pids()
	for i in range(window_count - 1):
		commands = ['--position', str(50 + (i + 1) * window_dist) + ',10']
		if other_args && add_custom_args:
			for arg in other_args.split(' '):
				commands.push_front(arg)
		pids.append(OS.execute(OS.get_executable_path(), commands, false))

func _client_pressed():
	var window_count: int = _get_setting('client/number_of_windows')
	var window_dist: int = _get_setting('client/window_distance')
	var add_custom_args: bool = _get_setting('client/add_custom_args')
	var first_args: String = _get_setting('client/first_window_args')
	var other_args: String = _get_setting('client/other_window_args')

	var commands = ['--position', '50,10']
	if first_args && add_custom_args:
		for arg in first_args.split(' '):
			commands.push_front(arg)

	var main_run_args = _get_setting('editor/main_run_args', false)
	if main_run_args != first_args:
		_set_setting('editor/main_run_args', first_args, false)
	var interface = get_editor_interface()
	interface.play_main_scene()
	if main_run_args != first_args:
		_set_setting('editor/main_run_args', main_run_args, false)

	kill_pids()
	for i in range(window_count - 1):
		commands = ['--position', str(50 + (i + 1) * window_dist) + ',10']
		if other_args && add_custom_args:
			for arg in other_args.split(' '):
				commands.push_front(arg)
		pids.append(OS.execute(OS.get_executable_path(), commands, false))

func _join_pressed():
	var window_count: int = _get_setting('join/number_of_windows')
	var window_dist: int = _get_setting('join/window_distance')
	var add_custom_args: bool = _get_setting('join/add_custom_args')
	var first_args: String = _get_setting('join/first_window_args')
	var other_args: String = _get_setting('join/other_window_args')

	var commands = ['--position', '50,10']
	if first_args && add_custom_args:
		for arg in first_args.split(' '):
			commands.push_front(arg)

	var main_run_args = _get_setting('editor/main_run_args', false)
	if main_run_args != first_args:
		_set_setting('editor/main_run_args', first_args, false)
	var interface = get_editor_interface()
	interface.play_main_scene()
	if main_run_args != first_args:
		_set_setting('editor/main_run_args', main_run_args, false)

	kill_pids()
	for i in range(window_count - 1):
		commands = ['--position', str(50 + (i + 1) * window_dist) + ',10']
		if other_args && add_custom_args:
			for arg in other_args.split(' '):
				commands.push_front(arg)
		pids.append(OS.execute(OS.get_executable_path(), commands, false))

func _loaddir_pressed():
	OS.shell_open(OS.get_user_data_dir())

# ******************************************************************************

func kill_pids():
	for pid in pids:
		OS.kill(pid)
	pids.clear()

func _remove_panels():
	for panel in panels:
		remove_control_from_container(CONTAINER_TOOLBAR, panel)
		panel.free()
	panels.clear()

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_F4:
			_server_pressed()

# ******************************************************************************

func _add_texture_button(action: String, icon_normal, icon_pressed):
	var panel = PanelContainer.new()
	var b = TextureButton.new()
	b.texture_normal = icon_normal
	b.texture_pressed = icon_pressed
	b.connect('pressed', self, action)
	panel.add_child(b)
	add_control_to_container(CONTAINER_TOOLBAR, panel)
	return panel

func _add_text_button(action: String, text):
	var panel = PanelContainer.new()
	var b = Button.new()
	b.text = text
	b.connect('pressed', self, action)
	panel.add_child(b)
	add_control_to_container(CONTAINER_TOOLBAR, panel)
	return panel

# ------------------------------------------------------------------------------

func _add_setting(name: String, type, value, auto_prefix:=true):
	if auto_prefix:
		name = settings_prefix + name
	if ProjectSettings.has_setting(name):
		return
	ProjectSettings.set(name, value)
	var property_info = {'name': name, 'type': type}
	ProjectSettings.add_property_info(property_info)

func _set_setting(name: String, value, auto_prefix:=true):
	if auto_prefix:
		name = settings_prefix + name

	ProjectSettings.set_setting(name, value)

func _get_setting(name: String, auto_prefix:=true):
	if auto_prefix:
		name = settings_prefix + name

	return ProjectSettings.get_setting(name)
