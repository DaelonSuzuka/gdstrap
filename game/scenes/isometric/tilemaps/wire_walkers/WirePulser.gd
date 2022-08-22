extends WireWalker

# ******************************************************************************

export(Color) var color = Color.white
export var random := false
export var super_random := false
export var intensity := 1.0
export var speed := .05 setget set_speed
func set_speed(new_speed):
	speed = new_speed
	speed_limiter.period = new_speed
export var delay := .1 setget set_delay
func set_delay(new_delay):
	delay = new_delay
	delay_limiter.period = new_delay

export var decay := .1
var target_color = Color.white

# ******************************************************************************

func refresh():
	.refresh()
#	HyperLog.log(self).text('speed')
#	HyperLog.log(self).text('delay')
#	HyperLog.log(self).text('intensity')
#	HyperLog.log(self).text('decay')
#	HyperLog.log(self).text('random')
#	HyperLog.log(self).text('super_random')
#	HyperLog.log(self).offset(Vector2(0, 40))

var next = []
var current_sequence = []

var speed_limiter = RateLimiter.new(speed)
var delay_limiter = RateLimiter.new(delay)
func _process(delta):
	if !active:
		return

	if !speed_limiter.check_time(delta):
		return
	
	if wire:
		for segment in wire.segments:
			lerp_modulate(segment, Color.white, decay)

	if next:
		var new_next = []
		for segment in next:
			if super_random:
				segment.modulate = Color.from_hsv(randf(), 1, 1) * intensity
			else:
				segment.modulate = target_color
			for neighbor in segment.neighbors.values():
				if neighbor in current_sequence:
					continue
				current_sequence.append(neighbor)
				new_next.append(neighbor)
		next.clear()
		next.append_array(new_next)
		return

	if !delay_limiter.check_time(delta):
		return
	current_sequence = []
	
	if random:
		target_color = Color.from_hsv(randf(), 1, 1) * intensity
	else:
		target_color = color * intensity
	if start:
		start.modulate = target_color
		next = start.neighbors.values()
