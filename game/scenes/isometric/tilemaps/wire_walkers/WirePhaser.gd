extends WireWalker

# ******************************************************************************

export var intensity := 1.0
export var speed := 1.0 setget set_speed
func set_speed(new_speed):
	speed = new_speed
	limiter.period = new_speed

export var transition_speed := .05
var target_color = Color.white

# ******************************************************************************

func refresh():
	.refresh()
	# HyperLog.log(self).text('intensity')
	# HyperLog.log(self).text('speed')
	# HyperLog.log(self).text('transition_speed')
	# HyperLog.log(self).text('target_color')

var limiter = RateLimiter.new(speed)
func _physics_process(delta):
	lerp_modulate(wire, target_color, transition_speed)
	
	if !limiter.check_time(delta):
		return
	
	target_color = Color.from_hsv(randf(), 1, 1) * intensity
