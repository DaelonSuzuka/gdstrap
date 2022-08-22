extends CanvasLayer

# ******************************************************************************

func show_debug():
	$Debug.show()

func hide_debug():
	$Debug.hide()

# ------------------------------------------------------------------------------

var debug_labels := {}

func debug(name: String, value):
	if name in debug_labels:
		debug_labels[name].text = str(value)
		return

	var label = $Debug/Spacer.duplicate(true)
	label.text = str(value)
	$Debug.add_child(label)
	debug_labels[name] = label
