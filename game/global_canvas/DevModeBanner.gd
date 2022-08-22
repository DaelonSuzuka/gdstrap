extends Control

func _ready():
	# $Label1/AnimationPlayer.current_animation = 'scroll'
	yield(get_tree().create_timer(6), "timeout")
	$Label2/AnimationPlayer.current_animation = 'scroll'
