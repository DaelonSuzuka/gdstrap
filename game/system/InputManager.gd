extends Node

# ******************************************************************************

signal input_event(event)

var state := {}
var actions := []
var paused := false

# ******************************************************************************

func _ready() -> void:
	for action in InputMap.get_actions():
		state[action] = false
		actions.append(action)

func register(object) -> void:
	if object.has_method('handle_input'):
		connect('input_event', object, 'handle_input')

# ******************************************************************************

func _notification(what) -> void:
	if what == MainLoop.NOTIFICATION_WM_FOCUS_OUT:
		paused = true
		for action in actions:
			state[action] = false
			var event = FakeEvent.new(action, false)
			emit_signal('input_event', event)
	if what == MainLoop.NOTIFICATION_WM_FOCUS_IN:
		paused = false

# ******************************************************************************

func _physics_process(delta) -> void:
	if paused:
		return
	for action in actions:
		if Input.is_action_pressed(action) != state[action]:
			state[action] = Input.is_action_pressed(action)
			var event = FakeEvent.new(action, state[action])
			emit_signal('input_event', event)
