extends Area2D

onready var animationPlayerNode = $AnimationPlayer
onready var collisionShapeNode = $CollisionShape2D

export var isOn = true
export var tag = ""
export var isOnInverted = false


func _ready():
	animationPlayerNode.play("On" if isOn else "Off")
	collisionShapeNode.disabled = not isOn


# выкл/выкл
func set_state(_isOn):
	isOn = _isOn
	
	animationPlayerNode.play("On" if (not isOn if isOnInverted else isOn)  else "Off")
	collisionShapeNode.disabled = isOn if isOnInverted else not isOn
