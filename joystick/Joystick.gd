extends TextureRect

onready var stickNode = $Stick
onready var stickDefaultPos = stickNode.rect_position

enum TYPES {
	JOYSTICK,
	RANGE_X,
	RANGE_Y
}
export var type = TYPES.JOYSTICK
export var joystickRadius := 128

var isPressed := false
var dir := Vector2()
var touchIndex := -1

var output = Vector2()


func _input(event):
	if event is InputEventScreenDrag:
		if event.index == touchIndex:
			update_output(event.position)


func update_output(_position):
	match type: 
		TYPES.JOYSTICK:
			stickNode.rect_position = (_position - rect_position - rect_pivot_offset).clamped(joystickRadius) - stickNode.rect_pivot_offset + rect_pivot_offset
		TYPES.RANGE_X:
			stickNode.rect_position.x = clamp(_position.x - rect_position.x - rect_pivot_offset.x, -joystickRadius, joystickRadius) - stickNode.rect_pivot_offset.x + rect_pivot_offset.x
		TYPES.RANGE_Y:
			stickNode.rect_position.y = clamp(_position.y - rect_position.y - rect_pivot_offset.y, -joystickRadius, joystickRadius) - stickNode.rect_pivot_offset.y + rect_pivot_offset.y
			
	output = stickNode.rect_position - rect_pivot_offset + stickNode.rect_pivot_offset


func set_active(_index):
	isPressed = true
	touchIndex = _index


func set_unactive():
	isPressed = false
	touchIndex = -1
	stickNode.rect_position = stickDefaultPos
	output = Vector2()
