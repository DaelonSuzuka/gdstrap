extends Reference
class_name RateLimiter

var period := 1.0

func _init(_period=1.0):
	period = _period

func reset():
	current_time = 0.0

var current_time := 0.0
func check_time(delta: float) -> bool:
	current_time += delta
	if current_time < period:
		return false
	reset()
	return true
