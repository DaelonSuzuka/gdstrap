extends Node

# ******************************************************************************

var local_target := 0

var offset := 0

var client_offsets := {}

var sync_timer = null

func _ready():
	# Network.connect('server_created', self, 'start_server')
	# Network.connect('connected_to_server', self, 'start_client')

	sync_timer = Timer.new()
	sync_timer.one_shot = true
	add_child(sync_timer)
	sync_timer.connect('timeout', self, 'start_client')

	Network.connect('connected_to_server', sync_timer, 'start', [1])

# func start_server():
# 	Console.print('start_server')

func start_client():
	rpc_id(1, 'register_client')

# ******************************************************************************

# server
remote func register_client():
	var id = get_tree().get_rpc_sender_id()
	var msg = {
		'server_time': Engine.get_physics_frames()
	}
	rpc_id(id, 'respond_to_ping', msg)

# client
remote func respond_to_ping(msg):
	msg['id'] = Network.net_id
	msg['client_time'] = Engine.get_physics_frames()
	rpc_id(1, 'collect_ping_response', msg)

# on server
remote func collect_ping_response(msg):
	var rtt = Engine.get_physics_frames() - msg.server_time
	msg['frame_offset'] = msg.client_time - msg.server_time - (rtt / 2)

	client_offsets[msg.id] = msg.frame_offset
	rpc_id(msg.id, 'set_client_timing', msg)

# back on client
remote func set_client_timing(msg):
	offset = msg.frame_offset
