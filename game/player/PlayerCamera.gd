extends Camera2D

# ******************************************************************************

var target: Node = null

func follow(node:Node, _zoom=null, speed=5):
	if is_instance_valid(node):
		target = node
	if _zoom is Vector2:
		zoom = _zoom
		original_zoom = _zoom
	smoothing_speed = speed

# ******************************************************************************

func _get_camera_center():
	var vtrans = get_canvas_transform()
	var top_left = -vtrans.get_origin() / vtrans.get_scale()
	var vsize = get_viewport_rect().size
	return top_left + 0.5*vsize/vtrans.get_scale()

export var force_current := true
func _process(delta):
	if force_current:
		current = true

	if !is_instance_valid(target):
		target = null

	if target and target.is_inside_tree():
		global_position = target.global_position
	
		if _get_camera_center().distance_to(target.global_position) < 10:
			smoothing_speed = lerp(smoothing_speed, 5, .1)

func _physics_process(delta):
	apply_shake(delta)

# ******************************************************************************
# ObserverCam features

# save the original zoom and position so we can reset it later
onready var original_zoom := zoom

func reset():
	zoom = original_zoom
	offset = Vector2()

# variables used to manage dragging
var active := false
var mouse_start_pos: Vector2
var offset_start: Vector2
var dragging := false

# ------------------------------------------------------------------------------

func _input(event):
	if !current:
		return

	if event is InputEventKey:
		if event.pressed:
			if event.as_text() == 'BackSlash':
				active = !active

	if !active:
		return

	if event is InputEventMouseButton:
		match event.button_index:
			BUTTON_MIDDLE:
				if event.pressed:
					mouse_start_pos = event.position
					offset_start = offset
					dragging = true
				else:
					dragging = false
					if mouse_start_pos == event.position:
						reset()
			BUTTON_WHEEL_UP:
				if zoom.x > 0.2 and zoom.y > 0.2:
					zoom -= Vector2(0.1, 0.1)
			BUTTON_WHEEL_DOWN:
				zoom += Vector2(0.1, 0.1)

	# do the actual dragging
	elif event is InputEventMouseMotion and dragging:
		offset = zoom * (mouse_start_pos - event.position) + offset_start

# ******************************************************************************
# Shake stuff

export var decay = 0.8  # How quickly the shaking stops [0, 1].
export var max_offset = Vector2(50, 30)  # Maximum hor/ver shake in pixels.
export var max_roll = 0.1  # Maximum rotation in radians (use sparingly).

var trauma = 0.0  # Current shake strength.
var trauma_power = 2  # Trauma exponent. Use [2, 3].
onready var noise = OpenSimplexNoise.new()
var noise_y = 0

func _ready():
	randomize()
	noise.seed = randi()
	noise.period = 4
	noise.octaves = 2
		
func apply_shake(delta):
	if !trauma:
		return
	trauma = max(trauma - decay * delta, 0)
	var amount = pow(trauma, trauma_power) / 10
	noise_y += 1
	# Using noise
	rotation = max_roll * amount * noise.get_noise_2d(noise.seed, noise_y)
	offset.x = max_offset.x * amount * noise.get_noise_2d(noise.seed*2, noise_y)
	offset.y = max_offset.y * amount * noise.get_noise_2d(noise.seed*3, noise_y)
	
func shake(amount):
	trauma = min(trauma + amount, 1.0)
