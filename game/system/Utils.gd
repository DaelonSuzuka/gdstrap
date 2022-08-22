extends Node

# ******************************************************************************

var _process_cache :={}
var _physics_process_cache :={}
var _playback_cache := {}

func _pause_node(node: Node, value: bool, force_physics:=false) -> void:
	var path = node.get_path()
	if node is AnimationPlayer:
		if value:
			_playback_cache[path] = node.playback_active
			node.playback_active = false
		else:
			if path in _playback_cache:
				node.playback_active = _playback_cache[path]

	if node is AudioStreamPlayer or node is AnimatedSprite:
		if value:
			_playback_cache[path] = node.playing
			node.playing = false
		else:
			if path in _playback_cache:
				node.playing = _playback_cache[path]

	if force_physics:
		node.set_process(!value)
		node.set_physics_process(!value)
	else:
		if value:
			_process_cache[path] = node.is_processing()
			node.set_process(false)
			_physics_process_cache[path] = node.is_physics_processing()
			node.set_physics_process(false)
		else:
			if path in _physics_process_cache:
				node.set_process(_physics_process_cache[path])
			if path in _process_cache:
				node.set_physics_process(_process_cache[path])

func _set_paused(node: Node, value: bool, force_physics:=false) -> void:
	for child in node.get_children():
		if child.get_child_count():
			_set_paused(child, value, force_physics)
		_pause_node(child, value, force_physics)

func pause(node: Node, force_physics:=false) -> void:
	_set_paused(node, true, force_physics)

func resume(node: Node, force_physics:=false) -> void:
	_set_paused(node, false, force_physics)

# ******************************************************************************

var collision_cache := {}

func _set_collision_enabled(node: Node, value: bool):
	if !node.get('collision_layer'):
		return
	var path = node.get_path()

	prints(path, node.collision_layer, value)

	if !value:
		collision_cache[path] = {
			layer = node.collision_layer,
			mask = node.collision_mask,
		}

		node.collision_layer = 0
		node.collision_mask = 0
	else:
		if path in collision_cache:
			node.collision_layer = collision_cache[path].layer
			node.collision_mask = collision_cache[path].mask

func set_collision_enabled(node: Node, value: bool):
	for child in node.get_children():
		if child.get_child_count():
			set_collision_enabled(child, value)
		_set_collision_enabled(child, value)

func enable_collision(node: Node):
	pass

func disable_collision(node: Node):
	pass

# ******************************************************************************

func attach_input_probe(node:Node):
	for child in node.get_children():
		if child.get_child_count():
			attach_input_probe(child)
		if node is Control:
			node.connect('gui_input', self, 'input_probe', [node.get_path()])

func input_probe(event, node):
	print(node, ' ', event)

# ******************************************************************************

func reparent_node(node:Node, new_parent:Node, legible_unique_name:=false) -> void:
	if !is_instance_valid(node) or !is_instance_valid(new_parent):
		return

	var old_parent = node.get_parent()
	if old_parent:
		old_parent.remove_child(node)

	new_parent.add_child(node, legible_unique_name)

# ******************************************************************************

func try_connect(src, sig, dest, method, args=[], flags=0):
	if dest.has_method(method):
		if !src.is_connected(sig, dest, method):
			src.connect(sig, dest, method, args, flags)

# ******************************************************************************

func get_all_children(node: Node, _children={}) -> Dictionary:
	_children[node.get_path()] = node

	for child in node.get_children():
		_children[child.get_path()] = child
		if child.get_child_count():
			get_all_children(child, _children)

	return _children

# ******************************************************************************

func get_datetime_string():
	var stamp = '{year}-{month}-{day}T{hour}:{minute}:{second}'
	return stamp.format(OS.get_datetime())

class Timestamp:
	var _time: int

	func _init(_period=1.0):
		_time = OS.get_ticks_msec()

	func time_since():
		return OS.get_ticks_msec() - _time

	func update():
		_time = OS.get_ticks_msec()

	func _to_string():
		return 'timestamp: %dms, %dms ago' % [_time, time_since()]
