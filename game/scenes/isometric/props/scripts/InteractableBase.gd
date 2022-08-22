tool
extends Node2D

# ******************************************************************************

export var active := true
export(NodePath) var target
export(String) var method
export(String) var argument

export var conversation := ''
export var entry := ''
export var line := 0

export(String, "sequential", "continuous") var dialog_type = "sequential"

# ------------------------------------------------------------------------------

export(float) var tooltip_offset = -75 setget set_tooltip_offset
func set_tooltip_offset(value):
	tooltip_offset = value
	if is_inside_tree():
		$Tooltip.position.y = value

export(String, MULTILINE) var tooltip_text = 'Use' setget set_tooltip_text
func set_tooltip_text(value):
	tooltip_text = value
	$Tooltip/Label.text = value

export(String, MULTILINE) var contents = ''
var opened = false

# ******************************************************************************

func _ready():
	set_tooltip_offset(tooltip_offset)
	$Tooltip.visible = Engine.editor_hint
	set_tooltip_text(tooltip_text)

# ******************************************************************************

func tooltip(object, value):
	if !active:
		return

	$Tooltip.visible = value

# ******************************************************************************

var state = ''

func interact(object):
	if !active:
		return

	if opened:
		var convo = '%s:%s:%d' % [conversation, entry, -1]
		Game.start_dialog(self, convo, {'len': 1})
		line += 1
		return

	if conversation:
		if dialog_type == "sequential":
			var convo = '%s:%s:%d' % [conversation, entry, line]
			Game.start_dialog(self, convo, {'len': 1})
			line += 1
		if dialog_type == "continuous":
			var convo = '%s:%s:%d' % [conversation, entry, line]
			Game.start_dialog(self, convo)
		return

	execute()

var should_open = false

func open():
	should_open = true

func conversation_over():
	Player.set_input_proxy(null)
	if !opened and contents and should_open:
		should_open = false
		Game.set_opened(self)
		Game.start_dialog(self, 'Common:GotItem')
		opened = true

	execute()

func execute():
	if target and method:
		var node = get_node(target)
		if node and node.has_method(method):
			if argument:
				node.call(method, argument)
			else:
				node.call(method)
