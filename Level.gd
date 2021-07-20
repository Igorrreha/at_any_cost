extends Node2D

onready var leversContainerNode = $Mecha/Levers
onready var doorsContainerNode = $Mecha/Doors
onready var spikesContainerNode = $Mecha/Spikes
onready var playerNode = $Player


func _ready():
	
	# соединение сигналов между механизмами
	for lever in leversContainerNode.get_children():
		
		# рычаг -> дверь
		for door in doorsContainerNode.get_children():
			if lever.tag == door.tag:
				lever.connect("state_changed", door, "set_opened")
		
		# рычаг -> шипы
		for spikes in spikesContainerNode.get_children():
			if lever.tag == spikes.tag:
				lever.connect("state_changed", spikes, "set_state")


func start_game():
	playerNode.inputIgnore = false
