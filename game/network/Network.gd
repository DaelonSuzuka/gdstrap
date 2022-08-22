extends Node

# ******************************************************************************

# server signals
signal server_created

# client signals
signal connected_to_server
signal failed_to_connect
signal disconnected_from_server

# player management signals
signal peer_connected(pinfo)
signal peer_disconnected(pinfo)

# ------------------------------------------------------------------------------

# backends
enum {
	ENET,
	WEBSOCKETS
}
var backend = ENET

var server_info = {
	name = "Server",
	max_players = 10,
	region = 'US-EAST',
	port = 9099,
}

var connection_info = {
	port = 9099,
	ip = 'skyknights.daelon.net',
}

var connected = false 
var is_server := false
var is_client := false
var net_id := 0

var player_registry := {}

var player_info = {
	name = '',
	net_id = 0,
	char_color = Color(1, 1, 1),
	steam_id = 0,
	key_items = [],
}

var default_scene = 'coliseum'

# ------------------------------------------------------------------------------

var prefix = '[color=green][NETWORK][/color] '
func Log(string: String):
	Console.print(prefix + string)

# ******************************************************************************

func _ready():
	get_tree().connect("connected_to_server", self, "_on_connected_to_server")
	get_tree().connect("connection_failed", self, "_on_connection_failed")
	get_tree().connect("server_disconnected", self, "_on_disconnected_from_server")
	
	register_console_commands()

	Args.parse()
	if Args.port:
		server_info.port = int(Args.port)
		connection_info.port = int(Args.port)

	if OS.has_feature('HTML5') or OS.has_feature('websockets') or Args.websockets:
		backend = WEBSOCKETS

	set_physics_process(false)
	if backend == WEBSOCKETS and !OS.has_feature('HTML5'):
		set_physics_process(true)

	# var node = load('res://network/ControlWebsocket.gd').new()
	# add_child(node)

# ******************************************************************************
# websocket client and server both need to be polled
var websocket = null
func _physics_process(delta):
	if websocket:
		websocket.poll()

# ******************************************************************************
# Server

func create_server():
	# connect signals
	get_tree().connect("network_peer_connected", self, "peer_connected_to_server")
	get_tree().connect("network_peer_disconnected", self, "peer_disconnected_from_server")

	var net = null
	var result = null

	if backend == WEBSOCKETS:
		net = WebSocketServer.new()
		result = net.listen(server_info.port, PoolStringArray(), true)
		websocket = net
	else:
		net = NetworkedMultiplayerENet.new()
		result = net.create_server(server_info.port, server_info.max_players)

	if result != OK:
		Log("Failed to create server, error code: " + str(result))
		return

	get_tree().set_network_peer(net)

	Log("Server created, hosting on port %s" % str(server_info.port))
	
	# update internal state
	net_id = get_tree().get_network_unique_id()
	connected = true
	is_server = true

	# set up 'player' data
	player_info.name = 'Server'
	player_info.net_id = 1
	register_player(player_info)
	emit_signal("server_created")

	register_server_commands()
	
	Game.load_scene(default_scene)

# server side player handling
func peer_connected_to_server(id):
	Log("Player %s connected" % str(id))

	# Send the server info to the new player
	rpc_id(id, "recieve_server_info", server_info)

	# tell the client to load the scene
	# TODO: this will need to be more transactional later on
	Game.rpc_id(id, "load_scene", default_scene)

func peer_disconnected_from_server(id):
	Log("Player %s disconnected (%s)" % [str(id), player_registry[id].name])
	
	unregister_player(id)

# ******************************************************************************
# Client

func join_server():
	if is_server:
		return

	# check settings
	var username = Settings.get_value('Username', '')
	if !username: # not allowed to connect with an empty username
		return
	player_info.name = username

	if Args.address:
		connection_info.ip = Args.address

	# create client
	var net = null
	var result = null
	var url = null

	if backend == WEBSOCKETS:
		net = WebSocketClient.new()
		url = 'ws://' + connection_info.ip + ':' + str(connection_info.port)
		result = net.connect_to_url(url, PoolStringArray(), true)
		websocket = net
	else:
		net = NetworkedMultiplayerENet.new()
		url = connection_info.ip
		result = net.create_client(url, connection_info.port)

	if result != OK:
		Log('Failed to create client ' + str(result))
		return
		
	get_tree().set_network_peer(net)

	Log('Client created, attempting to connect to ' + url)

func leave_server():
	if is_server:
		return
	Log('Attempting to disconnect from server')
	rpc_id(1, 'kick_me')
	_on_disconnected_from_server()
	
# ------------------------------------------------------------------------------
# Client functions

# Client connected to server
func _on_connected_to_server():
	emit_signal("connected_to_server")
	Log("server connection successful")
	connected = true
	is_client = true

	net_id = get_tree().get_network_unique_id()
	player_info.net_id = net_id

	# send our info to the server
	rpc_id(1, "register_player", player_info)

# Client failed to connect to server
func _on_connection_failed():
	emit_signal("failed_to_connect")
	get_tree().set_network_peer(null)

# Client disconnected from server
func _on_disconnected_from_server():
	Log("disconnected from server")
	get_tree().set_network_peer(null)
	emit_signal("disconnected_from_server")
	player_registry.clear()
	player_info.net_id = 0
	
	if !OS.has_feature("standalone"):
		get_tree().quit()

	if !Game.returningToMenu:
		Game.load_scene('mainMenu')

# Client recieves server info from server
remote func recieve_server_info(sinfo):
	if !is_server:
		server_info = sinfo

# ******************************************************************************

# Player management

# server only, RPC'd by the client
remote func register_player(pinfo):
	player_registry[pinfo.net_id] = pinfo
	rpc("player_registry_updated", player_registry)
	emit_signal('peer_connected', pinfo)

# server only, called directly on the server
func unregister_player(id):
	Log("Unregistering player with ID %s" % id)
	var pinfo = player_registry[id]
	player_registry.erase(id)
	rpc("player_registry_updated", player_registry)
	emit_signal("peer_disconnected", pinfo)

# client only
remote func player_registry_updated(registry):
	# check for new players
	for id in registry:
		if id in player_registry:
			continue
		player_registry[id] = registry[id]
		Log('adding player to registry: %s' % registry[id])
		emit_signal('peer_connected', registry[id])

	# check for missing players
	var removed_ids = []
	for id in player_registry:
		if id in registry:
			continue

		removed_ids.append(id)
		Log('removing player from registry: %s' % player_registry[id])
		emit_signal('peer_disconnected', player_registry[id].duplicate())

	for id in removed_ids:
		player_registry.erase(id)

# ------------------------------------------------------------------------------
# other utilities

remote func kick_me():
	var id = get_tree().get_rpc_sender_id()
	kick_player(id, 'you asked for it')

func kick_player(id, reason):
	Log('kicking player %s for reason: %s' % [player_registry[id], reason])
	if id in get_tree().get_network_connected_peers():
		rpc_id(id, "kicked", reason)
	get_tree().network_peer.disconnect_peer(id)

remote func kicked(reason):
	var msg = "You have been kicked from the server, reason: " + reason
	Log(msg)

# ******************************************************************************
# console commands

func register_console_commands():
	Console.add_command('connect', self, 'join_server').register()
	Console.add_command('disconnect', self, 'leave_server').register()

	Console.add_command('set_name', self, 'set_name')\
		.add_argument('scene', TYPE_STRING)\
		.set_description('Change your multiplayer name.')\
		.register()

	Console.add_command('set_address', self, 'set_address')\
		.add_argument('address', TYPE_STRING)\
		.set_description('Change the multiplayer server address.')\
		.register()

func register_server_commands():
	if is_server:
		Console.add_command('change_scene', self, 'change_scene')\
			.add_argument('scene', TYPE_STRING)\
			.set_description('Change the multiplayer scene.')\
			.register()

# ------------------------------------------------------------------------------

func set_name(new_name):
	Network.player_info.name = new_name

func set_address(address):
	Network.connection_info.ip = address

# ------------------------------------------------------------------------------

func change_scene(scene):
	if !(scene in Scenes.registry):
		Log('Invalid scene: ' + scene)
		return

	Log('Changing selected scene: ' + scene)
	Network.default_scene = scene
	
	Game.load_scene(default_scene)
	Game.rpc("load_scene", default_scene)
	Console.toggle_console()
