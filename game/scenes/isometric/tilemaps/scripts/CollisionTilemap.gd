extends TileMap

# ******************************************************************************

func _ready():
	hide()

# ******************************************************************************

func disable():
	set_collision_layer_bit(0, false)
	set_collision_mask_bit(0, false)

func enable():
	set_collision_layer_bit(0, true)
	set_collision_mask_bit(0, true)
