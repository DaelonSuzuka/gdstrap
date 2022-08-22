extends Node

# ******************************************************************************

signal ping_updated(peer, value)

const ping_interval = 1.0
const ping_timeout = 5.0

var ping_data = {}
var last = 0.0

func _ready():
	Network.connect('server_created', self, '_on_server_created')

func _on_server_created():
	Network.connect("peer_connected", self, "create_ping_entry")
	Network.connect("peer_disconnected", self, "remove_ping_entry")

# ******************************************************************************
# Ping entry management

func create_ping_entry(pinfo):
	var id = pinfo.net_id

	# Initialize the ping data entry
	var ping_entry = {
		pinfo = pinfo,
		timer = Timer.new(),          # Timer object to control the ping/pong loop
		signature = 0,                # Used to match ping/pong packets
		packet_lost = 0,              # Count number of lost packets
		last_ping = 0,                # Last measured time taken to get an answer from the peer
	}
	
	# Setup the timer
	ping_entry.timer.one_shot = true
	ping_entry.timer.wait_time = ping_interval
	ping_entry.timer.process_mode = Timer.TIMER_PROCESS_IDLE
	ping_entry.timer.connect("timeout", self, "_on_ping_interval", [id], CONNECT_ONESHOT)
	ping_entry.timer.set_name("ping_timer_" + str(id))
	
	add_child(ping_entry.timer)
	ping_data[id] = ping_entry
	ping_entry.timer.start()

func remove_ping_entry(pinfo):
	var id = pinfo.net_id

	ping_data[id].timer.stop()
	ping_data[id].timer.queue_free()
	ping_data.erase(id)

# ******************************************************************************
# internal ping stuff

func request_ping(dest_id):
	ping_data[dest_id].timer.connect("timeout", self, "_on_ping_timeout", [dest_id], CONNECT_ONESHOT)
	ping_data[dest_id].timer.start(ping_timeout)
	rpc_unreliable_id(dest_id, "on_ping", ping_data[dest_id].signature, ping_data[dest_id].last_ping)

remote func on_ping(signature, last_ping):
	rpc_unreliable_id(1, "on_pong", signature)
	emit_signal("ping_updated", Network.net_id, last_ping)

remote func on_pong(signature):
	if Network.is_client:
		return
	
	var id = get_tree().get_rpc_sender_id()
	
	if (ping_data[id].signature == signature):
		ping_data[id].last_ping = (ping_timeout - ping_data[id].timer.time_left) * 1000
		ping_data[id].timer.stop()
		ping_data[id].timer.disconnect("timeout", self, "_on_ping_timeout")
		ping_data[id].timer.connect("timeout", self, "_on_ping_interval", [id], CONNECT_ONESHOT)
		ping_data[id].timer.start(ping_interval)
		rpc_unreliable("ping_value_changed", id, ping_data[id].last_ping)
		emit_signal("ping_updated", id, ping_data[id].last_ping)

# on client
remote func ping_value_changed(id, value):
	emit_signal("ping_updated", id, value)

	ping_data[id] = value

	if id == Network.net_id:
		last = value
		GlobalCanvas.debug('ping', '%4d ms' % int(value))

func _on_ping_timeout(id):
	# Console.print("Ping timeout, destination peer " + str(id))
	ping_data[id].packet_lost += 1
	ping_data[id].signature += 1
	call_deferred("request_ping", id)

func _on_ping_interval(id):
	ping_data[id].signature += 1
	request_ping(id)
