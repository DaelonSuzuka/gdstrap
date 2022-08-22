extends Node

# ******************************************************************************

var websocket = WebSocketClient.new()

func _ready():
	websocket.connect('connection_established', self, 'on_connection_established')
	websocket.connect("data_received", self, "on_received_data")

	var result = websocket.connect_to_url('ws://localhost:8001')
	if result != OK:
		print('failed to websocket')


func _physics_process(delta):
	if websocket:
		websocket.poll()

func on_connection_established(protocol):
	websocket.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)

	var message = 'handshake'
	var packet = message.to_utf8()
	websocket.get_peer(1).put_packet(packet)

func on_received_data():
	print('received_data')
	var packet: PoolByteArray = websocket.get_peer(1).get_packet()
	# var parsed_data: Dictionary = JSON.parse(packet.get_string_from_utf8()).result
	print(packet.get_string_from_utf8())
