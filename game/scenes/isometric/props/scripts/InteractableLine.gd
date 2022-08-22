tool
extends "res://scenes/isometric/props/scripts/InteractableBase.gd"

# ******************************************************************************

export var length := 1.0 setget set_length
func set_length(value):
	length = value
	$Area2D/CollisionShape2D.shape.extents.y = 18 * length

export var flip_h := false setget set_flip
func set_flip(value):
	flip_h = value
	$Area2D.scale.x = -1.0 if flip_h else 1.0
	$Tooltip.rotation_degrees = 28 if flip_h else -28
	$Tooltip.material.set_shader_param('level', -0.531 if flip_h else 0.531)

# ******************************************************************************

func _ready():
	._ready()
	set_length(length)
	set_flip(flip_h)
