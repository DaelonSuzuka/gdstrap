extends CanvasLayer

# ******************************************************************************

var settings_file := 'settings.json'
var settings := {}
var widgets := {}
var save_requested := false
var active := false

var registrants := []

# ******************************************************************************

func _ready():
	load_settings()
	
	for setting in registrants:
		_register(setting)

var limiter = RateLimiter.new(.5)
func _physics_process(delta):
	if !limiter.check_time(delta):
		return

	if save_requested:
		save_settings()
		save_requested = false

# ******************************************************************************


func register(setting:Node):
	registrants.append(setting)

func _register(setting:Node):
	setting.connect('value_changed', self, 'value_changed', [setting.name])
	widgets[setting.name] = setting
	setting.value = get_value(setting.name, setting.default_value)

func value_changed(value, name):
	set_value(name, value)

func subscribe(setting_name:String, object:Node, method:String, extra_args=null):
	if extra_args:
		widgets[setting_name].connect('value_changed', object, method, extra_args)
	else:
		widgets[setting_name].connect('value_changed', object, method)
	widgets[setting_name].emit()

# ******************************************************************************

func set_value(name: String, value):
	settings[name] = value
	save_requested = true
	limiter.reset()

func get_value(name: String, default=null):
	if name in settings:
		return settings[name]
	settings[name] = default
	return default

# ******************************************************************************

func save_settings():
	Files.save_json(settings_file, settings)

func load_settings():
	var result = Files.load_json(settings_file)
	if result is Dictionary:
		for setting in result:
			settings[setting] = result[setting]
