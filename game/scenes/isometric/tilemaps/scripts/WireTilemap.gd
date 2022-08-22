tool
extends TileMap

# ******************************************************************************

export var active := true

var segments = {}
var wires = []

var segment_grid = {}
var unmatched_segments = []

# ******************************************************************************

class Wire extends Node2D:
	var segments := []

class WireSegment extends Sprite:
	var neighbors := {}
	var cell: Vector2
	var id: int
	var subtile
	var wire
	var segments: Dictionary

	func _to_string():
		return '[Segment:%s]' % [get_instance_id()]

# ******************************************************************************

func _ready():
	if !owner or Engine.editor_hint:
		return

	if !active:
		return

	self_modulate.a = 0
	# Player.camera.active = true

	create_segments()
	identify_neighbors()
	identify_wires()

	for child in get_children():
		if child.has_method('refresh'):
			child.refresh()

# ******************************************************************************

func create_segments():
	var used_cells = get_used_cells()
	for cell in used_cells:
		var id = get_cellv(cell)
		var pos = map_to_world(cell)
		var region = tile_set.tile_get_region(id)
		var mode = tile_set.tile_get_tile_mode(id)

		var subtile = null
		if mode == TileSet.AUTO_TILE:
			subtile = get_cell_autotile_coord(cell.x, cell.y)
			var tile_origin = region.position + subtile * cell_size
			region = Rect2(tile_origin, cell_size)

		var atlas = AtlasTexture.new()
		atlas.atlas = tile_set.tile_get_texture(id)
		atlas.region = region

		var segment = WireSegment.new()
		segment.texture = atlas
		segment.global_position = pos + Vector2(0, 4)
		segment.id = id
		segment.cell = cell
		segment.subtile = subtile
		segment.segments = segments

		segments[cell] = segment

		if !(cell.x in segment_grid):
			segment_grid[cell.x] = {}
		segment_grid[cell.x][cell.y] = segment

# ******************************************************************************

func identify_neighbors():
	var neighbor_offsets = [
		Vector2(0, 1),
		Vector2(1, 0),
		Vector2(1, 1),
		Vector2(0, -1),
		Vector2(-1, 0),
		Vector2(-1, -1),
		Vector2(1, -1),
		Vector2(-1, 1),
	]

	for segment in segments.values():
		for offset in neighbor_offsets:
			var cell = segment.cell + offset
			if cell in segments:
				if segment.id == segments[cell].id:
					segment.neighbors[cell] = segments[cell]

# ******************************************************************************

var claimed_segments := []
var segment_count := 0

func identify_wires():
	claimed_segments.clear()
	var wire_count = 0
	for segment in segments.values():
		if segment in claimed_segments:
			continue
		var wire = Wire.new()
		segment_count = 0
		wire.name = 'Wire' + str(wire_count)
		wire_count += 1
		add_child(wire)
		wires.append(wire)

		var current = [segment]
		var next = []
		while true:
			for seg in current:
				if seg in claimed_segments:
					continue
				claimed_segments.append(seg)
				if !(seg in wire.segments):
					wire.segments.append(seg)
					seg.wire = wire
					seg.name = 'Segment' + str(segment_count)
					segment_count += 1
					wire.add_child(seg)
				for neighbor in seg.neighbors.values():
					if neighbor in wire.segments:
						continue
					next.append(neighbor)
			current.clear()
			current.append_array(next)
			next.clear()
			if !current:
				break

# ******************************************************************************

# var selected_segment = null
# var highlighted_segments = []

# func _input(event):
# 	if !(event is InputEventMouseButton):
# 		return

# 	if !event.pressed:
# 		return
# 	if !(event.button_index in [1, 2]):
# 		return

# 	for segment in highlighted_segments:
# 		segment.modulate = Color.white
# 	highlighted_segments.clear()

# 	if selected_segment:
# 		HyperLog.remove_log(selected_segment)
# 		selected_segment = null

# 	if event.button_index == 1:
# 		get_tree().set_input_as_handled()
# 		var cell = world_to_map(to_local(get_global_mouse_position()))
# 		if cell in segments:
# 			var segment = segments[cell]
# 			selected_segment = segment
# 			highlighted_segments.append(segment)
# 			segment.modulate = Color.red
# 			for neighbor in segment.neighbors.values():
# 				neighbor.modulate = Color.orange
# 				highlighted_segments.append(neighbor)
# 			show_segment_data(segment)

# func show_segment_data(segment):
# 	HyperLog.log(segment).hide_name()
# 	HyperLog.log(segment).text('cell')
# 	HyperLog.log(segment).text('id')
# 	HyperLog.log(segment).text('subtile')
# 	HyperLog.log(segment).text('name')
# 	HyperLog.log(segment).text('wire')
