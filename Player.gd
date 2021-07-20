extends KinematicBody2D

onready var cameraNode = $Camera2D
onready var animationPlayerNode = $AnimationPlayer
onready var spriteNode = $Sprite
onready var crossNode = $Cross
onready var grabAreaNode = $GrabArea
onready var grabAreaCollisionShapeNode = $GrabArea/CollisionShape2D
onready var actionAreaNode = $ActionArea

export var isCanGrab = true
export var isCanClimb = false

var moveJoystickNode = load("res://joystick/Joystick.tscn").instance()
var actionJoystickNode = load("res://joystick/Joystick.tscn").instance()

var inputIgnore = true
var inpMoveLeft = false
var inpMoveRight = false
var inpClimb = false
var inpJump = false
var inpAction = false
var inpActionOnPress = true
var inpGrabRelease = false

var climbShift = Vector2(10,-12)

const gravity = 10

enum STATES {
	IDLE
	RUN
	JUMP
	FALL
	CLIMB
	GRAB
	WALL_JUMP
}
var state = STATES.IDLE

enum WALL_JUMP_TYPES {
	GRAB_JUMP
	WALL_JUMP
}

var isFlipped = false

var runAcc = 130
var maxRunSpeed = 100
var moveDecX = 360
var moveVec = Vector2(0,0)

var jumpForce = 200
var grabJumpVec = Vector2(70, 220)
var wallJumpVec = Vector2(170, 170)
var grabJumpDuration = 0.2

var checkpoint = Vector2(0,0)


# секретное ++
var heroRightActionHolded = false
# --

signal dead
signal game_ended


func _ready():
	checkpoint = position
	
	set_flip(true)


func _physics_process(delta):
	
	inpMoveLeft = Input.is_action_pressed("hero_left") or (moveJoystickNode.isPressed and abs(moveJoystickNode.output.angle_to(Vector2(-1,0))) < PI/2)
	inpMoveRight = Input.is_action_pressed("hero_right") or (moveJoystickNode.isPressed and abs(moveJoystickNode.output.angle_to(Vector2(1,0))) < PI/2)
	inpClimb = Input.is_action_pressed("hero_climb") or (moveJoystickNode.isPressed and abs(moveJoystickNode.output.angle_to(Vector2(0,-1))) < PI/4)
	inpGrabRelease = Input.is_action_pressed("hero_grab_release") or (moveJoystickNode.isPressed and abs(moveJoystickNode.output.angle_to(Vector2(0,1))) < PI/4)
	inpJump = Input.is_action_pressed("hero_jump") or (actionJoystickNode.isPressed and abs(actionJoystickNode.output.angle_to(Vector2(0,-1))) < PI/2)
	
	var prevInpAction = inpAction
	inpAction = Input.is_action_pressed("hero_action") or (actionJoystickNode.isPressed and abs(actionJoystickNode.output.angle_to(Vector2(0,1))) < PI/2)
	inpActionOnPress = not prevInpAction and inpAction
	
	
	# зацеп
	if not inputIgnore and isCanGrab and (state == STATES.JUMP or state == STATES.FALL or state == STATES.WALL_JUMP):
		for area in grabAreaNode.get_overlapping_areas():
			if area.is_in_group("grab_point"):
				moveVec = Vector2(0,0)
				state = STATES.GRAB
				animationPlayerNode.play("Grab")
				position = area.position - (grabAreaCollisionShapeNode.position * Vector2(-1, 1) if isFlipped else grabAreaCollisionShapeNode.position)
				
				if area.isClimbable:
					isCanClimb = true
				
				break
	
	if not (state == STATES.GRAB or state == STATES.CLIMB):
		if is_on_floor():
			
			# передвижение
			var inputVec = Vector2(0,0)
			
			if not inputIgnore and inpMoveLeft and moveVec.x <= 0:
				inputVec.x -= 1
			if (not inputIgnore and inpMoveRight and moveVec.x >= 0) or heroRightActionHolded:
				inputVec.x += 1
			
			if inputVec.length() == 0:
				# трение
				var runDir = 1 if moveVec.x > 0 else -1
				if abs(moveVec.x) > moveDecX * delta:
					moveVec.x -= moveDecX * delta * runDir
				else:
					moveVec.x = 0
			else:
				# бег
				if abs(moveVec.x + inputVec.x * runAcc) <= maxRunSpeed:
					moveVec.x += inputVec.x * runAcc
				else: 
					moveVec.x = maxRunSpeed * inputVec.x
		
		# гравитация
		if not is_on_floor():
			moveVec.y += gravity
		
			if is_on_wall() and state != STATES.IDLE:
				# прыжок от стены
				if state == STATES.JUMP and (inpMoveLeft and moveVec.x > 0) or (inpMoveRight and moveVec.x < 0):
					wall_jump(WALL_JUMP_TYPES.WALL_JUMP)
				elif state != STATES.WALL_JUMP and state != STATES.GRAB:
					# столкновение со стенами
					moveVec.x = 0
		
		move_and_slide(moveVec, Vector2(0, -1))
		
		# отражение
		if state != STATES.WALL_JUMP:
			if moveVec.x > 0:
				set_flip(false)
			elif moveVec.x < 0:
				set_flip(true)
		
		# смена стейта
		set_state()
	
	# перенесено из _input
	if not inputIgnore:
		# прыжок
		if inpJump:
			if is_on_floor():
				moveVec.y = -jumpForce
			
			# прыжок от стены из захвата
			elif state == STATES.GRAB:
				wall_jump(WALL_JUMP_TYPES.GRAB_JUMP)
		
		# затяжной прыжок от стены из захвата
		elif state == STATES.GRAB and ((inpMoveLeft and not isFlipped) or (inpMoveRight and isFlipped)):
			wall_jump(WALL_JUMP_TYPES.WALL_JUMP)
		
		# взбирание на уступ
		if inpClimb:
			if isCanClimb:
				isCanClimb = false
				state = STATES.CLIMB
				animationPlayerNode.play("Climb")
				
				position += (climbShift * Vector2(-1,1)) if isFlipped else climbShift
		
		# отцеп
		if inpGrabRelease and state == STATES.GRAB:
			isCanClimb = false
			isCanGrab = false
			state = STATES.JUMP
			
			# кулдаун захвата
			var timer = Timer.new()
			add_child(timer)
			timer.start(0.2)
			
			yield(timer, "timeout")
			timer.queue_free()
			isCanGrab = true
		
		# переключение рычагов
		if inpActionOnPress and is_on_floor():
			for area in actionAreaNode.get_overlapping_areas():
				if area.is_in_group("lever"):
					area.toogle_state()
	# --


# смена стейтов
func set_state():
	if is_on_floor():
		if not inputIgnore and ((inpMoveLeft and moveVec.x <= 0) or (inpMoveRight and moveVec.x >= 0)) or heroRightActionHolded:
			if state != STATES.RUN:
				if state == STATES.IDLE:
					animationPlayerNode.play("RunStart")
				else:
					animationPlayerNode.play("Run")
				
				state = STATES.RUN
		else:
			if abs(moveVec.x) > 0:
				animationPlayerNode.play("RunEnd")
				state = STATES.IDLE
				if is_on_wall():
					moveVec.x = 0
			else: 
				if state == STATES.FALL:
					animationPlayerNode.play("FallToIdle")
				else:
					animationPlayerNode.play("Idle")
					state = STATES.IDLE
		
		moveVec.y = 1
		
	elif state != STATES.WALL_JUMP:
		if moveVec.y < 0:
			state = STATES.JUMP
			animationPlayerNode.play("Jump")
		else:
			if state != STATES.FALL:
				animationPlayerNode.play("FallStart")
			else:
				animationPlayerNode.play("Fall")


# отражение
func set_flip(_is_flipped):
	spriteNode.flip_h = _is_flipped
	grabAreaNode.scale.x = -1 if _is_flipped else 1\
	
	isFlipped = _is_flipped


# прыжок от стены
func wall_jump(_jumpType):
	
	var jumpVec = Vector2(0,0)
	if _jumpType == WALL_JUMP_TYPES.GRAB_JUMP:
		jumpVec = grabJumpVec 
	else: 
		jumpVec = wallJumpVec
	
	isCanGrab = false
	isCanClimb = false
	
	moveVec = Vector2(jumpVec.x * (1 if spriteNode.is_flipped_h() else -1), -jumpVec.y)
	set_flip(not spriteNode.is_flipped_h())
	state = STATES.WALL_JUMP
	
	animationPlayerNode.stop()
	animationPlayerNode.play("WallJump")
	yield(animationPlayerNode, "animation_finished")
	state = STATES.FALL


# переход между анимациями
func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "RunStart":
		animationPlayerNode.play("Run")
	elif anim_name == "FallStart":
		animationPlayerNode.play("Fall")
		state = STATES.FALL
	elif anim_name == "FallToIdle":
		animationPlayerNode.play("Idle")
		state = STATES.IDLE
	elif anim_name == "Climb":
		animationPlayerNode.play("Idle")
		state = STATES.IDLE


# соприкосновение с препятствиями и чекпоинтами
func _on_CollisionArea_area_entered(area):
	if area.is_in_group("obstacle"):
		backToCheckpoint()
	elif area.is_in_group("checkpoint"):
		checkpoint = area.position
	elif area.is_in_group("game_end_area"):
		heroRightActionHolded = true
		inputIgnore = true
		
		emit_signal("game_ended")


# возврат к чекпоинту
func backToCheckpoint():
	moveVec = Vector2(0,0)
	state = STATES.IDLE
	position = checkpoint
	
	emit_signal("dead")
