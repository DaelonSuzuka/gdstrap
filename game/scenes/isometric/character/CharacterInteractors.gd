extends Node2D

# ******************************************************************************

onready var rays = [
	$Ray1,
	$Ray2,
	$Ray3,
	$Ray4,
	$Ray5,
]
var ray_originals = []

onready var avatar = get_parent()

var can_interact = true
var interact_timeout = RateLimiter.new()

# ******************************************************************************

func _ready():
	for ray in rays:
		ray_originals.append(ray.cast_to)

func interact(object):
	pass

# ******************************************************************************

# just for drawing collider debug lines
# func _draw():
	# draw_circle($Area2D.position, 35, Color.red)
	
	# for ray in rays:
	# 	draw_line(ray.position, ray.position + (ray.cast_to), Color.red)

# just for drawing collider debug lines
func _physics_process(delta):
	# update()
	
	if !can_interact:
		if interact_timeout.check_time(delta):
			can_interact = true

# rotate the raycasts that we use to find interactables
func rotate_interactors(angle:Vector2):
	if angle.x or angle.y:
		for i in rays.size():
			rays[i].cast_to = ray_originals[i].rotated(angle.angle())

# ******************************************************************************

# finds the best candidate for interaction
func check():
	var area = $Ray2.get_collider()
	if area:
		return area
	area = $Ray1.get_collider()
	if area:
		return area
	area = $Ray3.get_collider()
	if area:
		return area
	var areas = $Area2D.get_overlapping_areas()
	if areas:
		return areas[0]

func get_interactable(object):
	if object:
		if object.has_method('interact'):
			return object
		elif object.get_parent().has_method('interact'):
			return object.get_parent()
	return null

# ------------------------------------------------------------------------------

var current_interactable = null

func clear_current_tooltip():
	if !is_instance_valid(current_interactable):
		current_interactable = null
		return
	if current_interactable and current_interactable.has_method('tooltip'):
		current_interactable.tooltip(avatar, false)
		current_interactable = null

func check_tooltip():
	if can_interact:
		var object = get_interactable(check())
		if object and object.has_method('tooltip'):
			if current_interactable != object:
				object.tooltip(avatar, true)

		if !object:
			clear_current_tooltip()

		current_interactable = object

func attempt_interaction():
	if can_interact:
		can_interact = false
		var object = get_interactable(check())
		if object:
			object.interact(avatar)
			clear_current_tooltip()
