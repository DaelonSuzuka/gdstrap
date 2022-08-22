tool
extends "res://scenes/isometric/props/scripts/InteractableBase.gd"

# ******************************************************************************

export var radius := 10.0 setget set_radius
func set_radius(value):
	radius = value
	$Area2D/CollisionShape2D.shape.radius = radius

# ******************************************************************************

func _ready():
	._ready()