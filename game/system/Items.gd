extends Node

# ******************************************************************************

var key_items = {
	"core_data_lori": {
		display_name = "Lori's Core Data",
		icon = "res://shards/Lori/Lori-icon.png",
		splash = "res://shards/Lori/Lori-splash.png",
		description = 'gotta go fast lol'
	},
	"positron_chair": {
		display_name = "Positron Chair",
		icon = "res://assets/positron_chair_temp_icon.png",
		splash = "res://assets/positron_chair_temp_icon.png",
		description = 'gotta go EVEN FASTER'
	},
	"charge_data":{
		display_name = "Energy Tank Charge",
		icon = "res://shards/Plasma/Plasma-icon.png",
		splash = "res://shards/Plasma/Plasma-splash.png",
		description = 'A large data packet absorbed from an energy tank. It feels like you had ten cups of coffee'
	},
	"corrupted_data":{
		display_name = "Corrupted Data Packet",
		icon = "res://shards/Lori/Lori-icon.png",
		splash = "res://shards/Lori/Lori-icon.png",
		description = 'This data packet pulses oddly. Maybe someone can extract some useable data from it?'
	}
}

var consumables = {
	"repair_kit": {
		display_name = "Repair Kit",
		icon = "res://shards/Heal/Heal-icon.png",
		splash = "res://shards/Heal/Heal-splash.png",
		description = 'The H34 Lemur is a compact multipurpose repair drone. Heals 100 HP'
	},
	"shield_charger": {
		display_name = "Shield Charge",
		icon = "res://shards/Plasma/Plasma-icon.png",
		splash = "res://shards/Plasma/Plasma-splash.png",
		description = 'Alcyon Accelerants Autonomous Defence Matrix Reinforcement, or AAADMR, is a set of tuned capacitors designed to rapidly recharge shield systems'
	}
}

var plugins = {
	"Shield_AA": {
		display_name = "Alcyon Accelerants Defence Matrix",
		icon = "res://shards/Plasma/Plasma-icon.png",
		splash = "res://shards/Plasma/Plasma-splash.png",
		description = 'Alcyon Accelerants consumer grade shield system.'
	},
	"Shield_KK": {
		display_name = "Komrad Krikonis Iron Wall",
		icon = "res://shards/Plasma/Plasma-icon.png",
		splash = "res://shards/Plasma/Plasma-splash.png",
		description = 'Komrad Krikonis Standard Personal Defence Equipment. Fight the power!'
	},
	"HP_Data_100": {
		display_name = "HANCENT GMBH Health Booster",
		icon = "res://shards/Plasma/Plasma-icon.png",
		splash = "res://shards/Plasma/Plasma-splash.png",
		description = 'The engineers at HANCENT, after many years, succeeded in adjusting core data to boost health performance'
	}
}

var libraries = {
	"fingerblaster": {
		display_name = "Finger Blaster",
		icon = "res://shards/Plasma/Plasma-icon.png",
		splash = "res://shards/Plasma/Plasma-splash.png",
		description = 'Upgrades the standard digital projectile system'
	},
# future ideas here:
# melee mastery (leads to the ranged double hit on melee shards)
# projectile mastery (increased damage and some side effects)
# elemental mastery (one for each element, boosts the elemental effects and damage)
# 

}


func get_info(item):
	if item in key_items:
		return key_items[item]

	elif item in consumables:
		return consumables[item]
		
	elif item in plugins:
		return plugins[item]
		
	elif item in libraries:
		return libraries[item]
		
	return null
