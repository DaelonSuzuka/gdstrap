extends Node2D

# ******************************************************************************

onready var avatar = get_parent()

# ******************************************************************************

func calculate_speed() -> float:
	var _speed = 1
	
	if avatar.input_state['run']:
		_speed += 0.25

	return _speed

func calculate_velocity() -> Vector2:
	var vel := Vector2()
	if avatar.input_state['move_up']:
		vel.y = -1
	if avatar.input_state['move_down']:
		vel.y = 1
	if avatar.input_state['move_left']:
		vel.x = -1
	if avatar.input_state['move_right']:
		vel.x = 1
	return vel.normalized()

# ------------------------------------------------------------------------------

var slope_height = {
	'1': 8.0,
	'2': 16.0,
	'3': 32.0,
}

func calculate_slope(vel:Vector2) -> Vector2:
	var slope = avatar.slope

	var pos = slope.world_to_map(slope.to_local(global_position))
	avatar.cell = slope.get_cellv(pos)

	var i = 0
	while avatar.cell == -1:
		pos = slope.world_to_map(slope.to_local(global_position + (Vector2(0, 16) * i)))
		avatar.cell = slope.get_cellv(pos)

		# reset and quit after five tries
		if i >= 5:
			avatar.cell = null
			return vel
		i += 1

	var up_direction = 'r'
	if slope.is_cell_x_flipped(pos.x, pos.y):
		up_direction = 'l'

	var tile_name = slope.tile_set.tile_get_name(avatar.cell)
	return rotate_raw2ramp(vel, slope_height[tile_name[0]], up_direction)

func rotate_raw2ramp(vel:Vector2, pixel_height, up_direction, tile_size=32) -> Vector2:
	if up_direction == 'l':
		vel.x = -vel.x

	# we can only normalize here because we're taking raw inputs
	var dir3 = Vector3(vel.normalized().x, vel.normalized().y, 0)
	
	# get ramp angle from known projection
	var ramp_angle = atan((sqrt(6) / 3) * (pixel_height - 1) / (tile_size - 1))
	
	# perform a series of rotations
	var r1 = dir3.rotated(Vector3(0, 0, 1), deg2rad(45))
	# lift the vector from the ground
	var r2 = r1.rotated(Vector3(0, 1, 0), ramp_angle)
	# rerotate to be offset by 45
	var r3 = r2.rotated(Vector3(0, 0, 1), deg2rad(-45))
	# tilt into the plane
	var r4 = r3.rotated(Vector3(1, 0, 0), deg2rad(-60))
	
	var result = Vector2(r4.x, r4.y)
	if up_direction == 'l':
		result.x = -result.x
	return result

# ------------------------------------------------------------------------------

func calculate_isometric_velocity(vel:Vector2) -> Vector2:
	var iso_vel = vel
	iso_vel.y /= 2
	if avatar.slope:
		iso_vel = calculate_slope(vel)
	return iso_vel.normalized()

func calculate_direction(vel:Vector2) -> int:
	var dir = 0
	if vel.length() > 0.01:
		dir = (int(8 * vel.angle() / (2 * PI) + 8.5) + 3) % 8
	return dir
