extends Node2D

# ******************************************************************************

func _ready():
	OS.set_window_title('gdstrap')

	# do not automatically load scene if game was launched via F6
	if Game.direct_launch:
		return

	var scene = 'mainmenu'
	if Args.scene:
		scene = Args.scene
	Game.load_scene(scene)
