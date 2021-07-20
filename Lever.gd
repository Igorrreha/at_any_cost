extends Area2D

onready var animationPlayerNode = $AnimationPlayer

export var isOn = false
export var tag = ""

signal state_changed(_isOn)


func _ready():
	animationPlayerNode.play("On" if isOn else "Off")


# выкл/выкл
func toogle_state():
	isOn = not isOn
	
	emit_signal("state_changed", isOn)
	animationPlayerNode.play("On" if isOn else "Off")
