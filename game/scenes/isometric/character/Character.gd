extends KinematicBody2D

# ******************************************************************************

onready var body = $Body
onready var movement = $Movement
onready var interactors = $Interactors

var walkDirections = {
	0: "UpLeft",
	1: "Up",
	2: "UpRight",
	3: "Right",
	4: "DownRight",
	5: "Down",
	6: "DownLeft",
	7: "Left",
}

# ******************************************************************************

var slope = null
var cell = null

func _ready():
	$TileDetector.connect('body_entered', self, '_on_body_entered')
	$TileDetector.connect('body_exited', self, '_on_body_exited')

# ******************************************************************************

func find_region_handler(tilemap):
	if tilemap.has_method('enter_region'):
		return tilemap
	else:
		if tilemap.get_parent():
			return find_region_handler(tilemap.get_parent())
	return null

func _on_body_entered(tilemap):
	if tilemap.name == 'Slopes':
		# print('entering slope')
		slope = tilemap
		return
		
	var handler = find_region_handler(tilemap)
	if handler:
		handler.enter_region(tilemap.name)

func _on_body_exited(tilemap):
	if tilemap.name == 'Slopes':
		# print('leaving slope')
		slope = null
		cell = null
		return

	var handler = find_region_handler(tilemap)
	if handler:
		handler.leave_region(tilemap.name)

# ******************************************************************************

func enter_world(world: Node):
	if !world.has_node('Spawns/Default'):
		return
	world.add_child(self)

	var spawn_name = 'Default'
	var spawns = world.get_node('Spawns')

	if Game.continuing:
		position = str2var(Game.data.position)
		Game.continuing = false
	else:
		if Game.direct_launch:
			if spawns.has_node('Dev'):
				spawn_name = 'Dev'
		if Game.requested_spawn:
			if spawns.has_node(Game.requested_spawn):
				spawn_name = Game.requested_spawn
				

		position = spawns.get_node(spawn_name).position
	
	interactors.current_interactable = null
	visible = true

func activate():
	visible = true
	clear_input()

func deactivate():
	visible = false
	clear_input()

# ******************************************************************************

var input_state = {
	'run': false,
	'move_up': false,
	'move_down': false,
	'move_left': false,
	'move_right': false,
	'activate': false,
}

func clear_input():
	for input in input_state:
		input_state[input] = false

func handle_input(event):
	if event.get('action') and event.action in input_state:
		input_state[event.action] = event.pressed

	if event is InputEventKey:
		if event.pressed:
			if event.as_text() == 'F3':
				movement_enabled = !movement_enabled

# ------------------------------------------------------------------------------

var waypoint = null
var waypoint_path := []

func add_waypoint(pos: Vector2, force=false):
	if force:
		clear_waypoint()
	var nav = get_parent().find_node("Navigation", true)
	if nav:
		var path = Array(nav.get_simple_path(global_position, pos, true))

		if !waypoint:
			waypoint = path[0]
		waypoint_path += path
	else:
		if !waypoint:
			waypoint = pos
		else:
			waypoint_path.append(pos)

func clear_waypoint():
	waypoint = null
	waypoint_path.clear()

func update_waypoint():
	if waypoint and global_position.distance_to(waypoint) < 1:
		waypoint = null

	if !waypoint and waypoint_path:
		waypoint = waypoint_path.pop_front()

# ------------------------------------------------------------------------------

var target = null

func follow(node):
	if is_instance_valid(node) and node.is_inside_tree():
		target = node

func clear_target():
	target = null

# ------------------------------------------------------------------------------

var direction := 0
var velocity := Vector2()
var speed := 0.0
var movement_enabled = true
var dead := false

func _physics_process(delta):
	if dead:
		return

	speed = movement.calculate_speed()
	# body.speed_scale = speed

	body.visible = true
	
	if input_state['activate']:
		input_state['activate'] = false
		interactors.attempt_interaction()

	var isometric_velocity
	velocity = movement.calculate_velocity()
	if velocity:
		# direct control
		clear_waypoint()
		clear_target()
		isometric_velocity = movement.calculate_isometric_velocity(velocity)
		if movement_enabled:
			move_and_collide(isometric_velocity * speed * delta * 100)
	else:
		# auto movement
		if target and is_instance_valid(target):
			# target following
			velocity = global_position.direction_to(target.global_position)

			var distance = global_position.distance_to(target.global_position)
			if distance < 1:
				speed *= distance
		else:
			# waypoint movement
			update_waypoint()
			if waypoint:
				velocity = global_position.direction_to(waypoint)
		
		# apply auto movement
		if slope:
			velocity = movement.calculate_slope(movement.calculate_isometric_velocity(velocity))
		if movement_enabled and is_inside_tree():
			move_and_collide(velocity * speed * delta * 100)

	# make animations match movement
	if velocity:
		direction = movement.calculate_direction(velocity)

		walk()
		play_footstep_sound()
	else:
		idle()

	Game.data.position = var2str(Vector2(position))
	Game.save_requested = true

	if isometric_velocity:
		interactors.rotate_interactors(isometric_velocity)
		interactors.check_tooltip()

# ******************************************************************************

func walk():
	pass

func idle():
	pass

# ------------------------------------------------------------------------------

var footstep_sounds = [
	
]

onready var footstep_player = {
	# true: $FootstepSound1,
	# false: $FootstepSound2,
}

var last_frame = 0
var last_anim = ''
var frame_count = 0
var audio_player = false

func play_footstep_sound():
	pass
	# if !visible or (body.frame == last_frame and body.animation == last_anim):
	# 	return
	# if !walking:
	# 	return
	# last_frame = body.frame
	# last_anim = body.animation
	# if frame_count >= 3:
	# 	frame_count = 0
	# 	footstep_player[audio_player].pitch_scale = rand_range(.9, 1.1)
	# 	footstep_player[audio_player].stream = footstep_sounds[randi() % footstep_sounds.size()]
	# 	footstep_player[audio_player].play()
	# 	audio_player = !audio_player
	# frame_count += 1

# ******************************************************************************

func get_item():
	direction = 5
#	body.play('GetItem')

# ******************************************************************************

func get_state():
	return {
		pos = global_position,
		input = input_state,
		vis = visible,
	}

func set_state(dict):
	global_position = dict['pos']
	input_state = dict['input']
	visible = dict['vis']
