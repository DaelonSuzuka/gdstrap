extends Node2D
class_name WireWalker

# ******************************************************************************

export var active := true

var tile_map = null
var start = null
var wire = null
export var max_distance := 3

# ******************************************************************************

func refresh():
	tile_map = get_parent()
	if !(tile_map is TileMap):
		return

	var cell = tile_map.world_to_map(tile_map.to_local(global_position))
	if cell in tile_map.segments:
		# if directly on a segment
		start = tile_map.segments[cell]
		wire = start.wire
	else:
		var check_cell = [] 
		var cell_found = false	
		for n in max_distance:
			for i in max_distance:
				if n == 0 and i == 0:
					continue
				else:
					check_cell.append(cell + Vector2(n,i))
					check_cell.append(cell + Vector2(-n,i))
					check_cell.append(cell + Vector2(n,-i))
					check_cell.append(cell + Vector2(-n,-i))

		var current_cell = Vector2(0,0)
		for g in check_cell:	
			if g in tile_map.segments:
				start = tile_map.segments[g]
				wire = start.wire
				cell_found = true
				break
		if !cell_found:
			print('No Wires Close Enough')

		# not directly on a segment
		# find closest segment and bind to it
		# TODO: this could be made much faster by starting near `cell` and
		# searching outward in a spiral
		#@yoobin try to implement a better search on your own
#		var closest := Vector2()
#		var closest_distance := max_distance
#		for segment in tile_map.segments:
#			var distance = cell.distance_to(segment)
#			if distance <= closest_distance:
#				closest = segment
#				closest_distance = distance
#
#		if closest in tile_map.segments:
#			start = tile_map.segments[closest]
#			wire = start.wire

# ******************************************************************************

func lerp_modulate(node, target, weight=.1):
	var _color = node.modulate
	_color = _color.linear_interpolate(target, weight)
	node.modulate = _color
