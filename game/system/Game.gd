extends Node

# ******************************************************************************
var prefix = '[color=gray][GAME][/color] '
func Log(string: String):
	Console.print(prefix + string)
# ******************************************************************************

var version = load('res://system/Version.gd').new().VERSION

# just used for the pause menu to communicate to the main menu
var returningToMenu := false
var continuing := false
var main_ready := true

signal scene_changed

var world_container: Node = null
var world: Node = null

func _ready():
	randomize()
	load_data()
	
	Diagraph.sandbox.call_deferred('add_locals', {
		'Game': self,
		'Player': Player,
	})

	if fix_direct_launch():
		world_container = get_node('/root/Main/World')

# ******************************************************************************
"""
This section fixes the scene tree when a scene is launched directly from the editor.

Main game systems are built with the assumption that the 'current scene' is
Main.tscn. Levels are loaded in as children of 'Main/World'. Launching a scene
directly from the editor causes that scene to be the 'current scene'.

Fixed this requires saving a reference to the directly launched scene, removing
it from the root viewport so it doesn't get deleted, and then calling 
'get_tree().change_scene()'.

Changing the scene takes longer than one game frame, for <reasons>, so this
process has involves multiple uses of 'call_deferred'.
"""

var direct_launch := false

func fix_direct_launch() -> bool:
	var scene = get_tree().get_current_scene()
	if scene.name != 'Main':
		direct_launch = true
		main_ready = false
		call_deferred('fix_main1')
		return false
	return true

var saved_current_scene: Node = null

func fix_main1():
	var scene = get_tree().get_current_scene()
	scene.get_parent().remove_child(scene)
	saved_current_scene = scene
	get_tree().change_scene("res://Main.tscn")
	call_deferred('fix_main2')

func fix_main2():
	world_container = get_node('/root/Main/World')
	if saved_current_scene is Control:
		get_node('/root/Main/CanvasLayer').add_child(saved_current_scene)
	else:
		world_container.add_child(saved_current_scene)
	world = saved_current_scene
	update_scene()
	emit_signal('scene_changed')
	main_ready = true

# ******************************************************************************

var suspended_scene: Node = null
var current_encounter: Node = null

# ONLY used for single player story mode battles
# func start_battle(encounter):
# 	Log('start_battle')

# 	if !Network.connected:
# 		suspended_scene = world_container.get_child(0)
# 		Utils.pause(suspended_scene, true)
# 		world_container.remove_child(suspended_scene)
# 	else:
# 		world_container.get_child(0).visible = false

# 	current_encounter = encounter
# 	LocalBattle.setup(encounter)
# 	LocalBattle.connect('battle_completed', self, 'battle_over', [], CONNECT_ONESHOT)

# 	Player.enter_battle(LocalBattle)
# 	LocalBattle.start()

# ONLY used for single player story mode battles
# func battle_over(result):
# 	Log('end_battle')
# 	if current_encounter.has_method('battle_over'):
# 		current_encounter.battle_over()
# 	LocalBattle.visible = false

# 	if !Network.connected:
# 		world_container.add_child(suspended_scene)
# 		Utils.resume(suspended_scene, true)
# 		suspended_scene = null
# 	else:
# 		world_container.get_child(0).visible = true

# ******************************************************************************
# Scene/World management

var requested_spawn = ''

remote func load_scene(scene_path: String, spawn:='', _continuing=false):
	Log('loading scene: ' + scene_path)
	requested_spawn = spawn
	continuing = _continuing

	if scene_path in Scenes.registry:
		scene_path = Scenes.registry[scene_path]

	var new_scene = load(scene_path) as PackedScene
	if new_scene:
		if world:
			world.queue_free()
		world = null
		world = new_scene.instance()
		world_container.add_child(world)
	else:
		Log('scene not found, aborting scene load')
		return

	update_scene()
	emit_signal('scene_changed')

# ------------------------------------------------------------------------------

var out := false

func _input(event):
	if !(event is InputEventKey):
		return
	if !event.pressed:
		return
	if event.as_text() == 'F7':
		if out:
			fade_in()
		else:
			fade_out()
		out = !out

func fade_out():
	if main_ready:
		get_node('/root/Main/FadePlayer').play('fade_out')

func fade_in():
	if main_ready:
		get_node('/root/Main/FadePlayer').play('fade_in')

func dim():
	if main_ready:
		get_node('/root/Main/FadePlayer').play('dim')

# ******************************************************************************
# Dialog helpers

func popup_dialog(object, conversation, options={}):
	var popup = Diagraph.canvas.popup_dialog(object, conversation, options)

func start_dialog(object, conversation, options={}):
	var dialog = Diagraph.canvas.start_dialog(object, conversation, options)

	Player.set_input_proxy(object)
	Utils.try_connect(dialog, 'done', Player, 'set_input_proxy')

# ******************************************************************************

func pause_world():
	if world:
		Utils.pause(world)

func resume_world():
	if world:
		Utils.resume(world)

# ******************************************************************************

var data_file = 'game_data.json'
var data = {
	scene = '',
	region = '',
	position = var2str(Vector2()),
	flags = {},
	opened_items = [],
}
var save_requested := false

var limiter = RateLimiter.new(.5)
func _physics_process(delta):
	if !limiter.check_time(delta):
		return

	if save_requested:
		save_data()
		save_requested = false

# ------------------------------------------------------------------------------

func update_scene():
	if world.name == 'MainMenu':
		return
	data.scene = world.filename
	save_requested = true

# ------------------------------------------------------------------------------
# game state flags

func set_flag(flag_name, value=true):
	data.flags[flag_name] = value
	save_requested = true

func get_flag(flag_name):
	if flag_name in data.flags:
		return data.flags[flag_name]
	return null

# ------------------------------------------------------------------------------
# item box state management

func set_opened(node: Node):
	var path = node.owner.get_parent().get_path_to(node)
	if !(path in data.opened_items):
		data.opened_items.append(path)
	save_requested = true
	limiter.reset()

func get_opened(node: Node):
	var path = node.owner.get_parent().get_path_to(node)
	return path in data.opened_items

# ------------------------------------------------------------------------------

func save_data():
	Files.save_json(data_file, data)

func load_data():
	var result = Files.load_json(data_file)
	if result is Dictionary:
		for key in data:
			if key in result:
				data[key] = result[key]
