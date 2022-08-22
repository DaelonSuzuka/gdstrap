extends CanvasLayer

# ******************************************************************************

onready var MenuButtons = find_node('MenuButtons')

# ******************************************************************************

func _ready():
	Player.push_menu(self)

	for btn in MenuButtons.get_children():
		connect_button(btn)

	MenuButtons.get_child(0).grab_focus()

func on_tree_exit():
	Player.pop_menu()

func connect_button(button):
	button.connect('pressed', self, 'pressed', [button])

# ******************************************************************************

func handle_input(event):
	pass

# ******************************************************************************

func pressed(button):
	match button.name:

		'Continue':
			pass
		'NewGame':
			pass
		'DevRoomIso':
			Game.load_scene('devroomiso')
		'DevRoomSide':
			Game.load_scene('devroomside')
		'DevRoomTop':
			Game.load_scene('devroomtop')
		'Options':
			pass
		'Exit':
			get_tree().quit()
