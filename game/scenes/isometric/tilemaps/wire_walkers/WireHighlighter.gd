extends WireWalker

# ******************************************************************************

export(Color) var color = Color.white

# ******************************************************************************

func refresh():
	.refresh()

	highlight_neighbors(start)

# ******************************************************************************

#TODO: replace this recursive solution with just modulating the wire

var highlighted_segments = []

func highlight_neighbors(segment, level=0):
	segment.modulate = color
	if level == 0:
		highlighted_segments.clear()
		highlighted_segments.append(segment)
	
	for neighbor in segment.neighbors.values():
		if !(neighbor in highlighted_segments):
			highlighted_segments.append(neighbor)
			highlight_neighbors(neighbor, level+1)
