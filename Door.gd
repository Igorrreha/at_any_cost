extends StaticBody2D

onready var animationPlayerNode = $AnimationPlayer 
onready var collisionShapeNode = $CollisionShape2D

export var isOpened = false
export var tag = ""


func _ready():
	animationPlayerNode.play("Off" if isOpened else "On")
	collisionShapeNode.disabled = isOpened


func set_opened(_isOpened):
	isOpened = _isOpened
	
	animationPlayerNode.play("Off" if isOpened else "On")
	collisionShapeNode.disabled = isOpened
