extends Node

var lvlScene = preload("res://levels/0_lvl.tscn")

onready var logoNode = $UI/Logo
onready var logoTweenNode = $UI/Logo/Tween
onready var logoAnimationPlayerNode = $UI/Logo/AnimationPlayer
onready var levelContainerNode = $LevelContainer
onready var levelNode = $LevelContainer/Level
onready var levelContainerTweenNode = $LevelContainer/Tween
onready var playerNode = $LevelContainer/Level/Player
onready var helpMenuNode = $UI/HelpMenu
onready var helpMenuTimerLabelNode = $UI/HelpMenu/BG/VBoxContainer/SpeedrunTime
onready var helpMenuSecretLabelNode = $UI/HelpMenu/BG/VBoxContainer/Secret
onready var speedrunTimerNode = $LevelContainer/SpeedrunTimer
onready var endScreenNode = $UI/EndScreen
onready var endScreenTweenNode = $UI/EndScreen/Tween
onready var endScreenTextTweenNode = $UI/EndScreen/TextTween
onready var endScreenLabelNode = $UI/EndScreen/Label
onready var inputContainerNode = $UI/Input
onready var moveJoystickNode = $UI/Input/JoystickMove
onready var actionJoystickNode = $UI/Input/JoystickAction

var helpMenuToggleInProcess = false
var helpMenuIsOpened = false

var gameStarted = false

var isAlive = true
var timeOver = false

var secretSpeedrunPart = "mgsht"
var secretAlivePart = "trcsvh"
var secretPhrase = ".." + secretAlivePart + secretSpeedrunPart

var gameEnded = false


func _ready():
	
	#inputContainerNode.visible = true if OS.get_name() == "Android" else false
	
	playerNode.connect("dead", self, "alive_challenge_failed")
	playerNode.connect("game_ended", self, "end_the_game")
	
	playerNode.moveJoystickNode = moveJoystickNode
	playerNode.actionJoystickNode = actionJoystickNode
	
	helpMenuSecretLabelNode.text = secretPhrase
	
	logoAnimationPlayerNode.play("InOut")
	yield(logoAnimationPlayerNode, "animation_finished")
	
	levelContainerTweenNode.interpolate_property(levelContainerNode, "modulate", levelContainerNode.modulate, Color(1,1,1,1), 6.75, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	levelContainerTweenNode.start()
	logoTweenNode.interpolate_property(logoNode, "modulate", logoNode.modulate, Color(1,1,1,0), 6.75, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	logoTweenNode.start()
	yield(logoTweenNode, "tween_completed")
	
	toogle_help_menu()
	start_game()


func _process(delta):
	helpMenuTimerLabelNode.text = str(int(speedrunTimerNode.time_left))


func start_game():
	levelNode.start_game()


func toogle_help_menu(_force = false):
	
	if _force or not helpMenuToggleInProcess:
		helpMenuToggleInProcess = true
		
		var tween1 = Tween.new()
		var tween2 = Tween.new()
		helpMenuNode.add_child(tween1)
		helpMenuNode.add_child(tween2)
		tween1.interpolate_property(helpMenuNode, "margin_left", helpMenuNode.margin_left, (-100 if helpMenuIsOpened else 0), 0.5, 
				Tween.TRANS_LINEAR, Tween.EASE_OUT)
		tween2.interpolate_property(helpMenuNode, "margin_right", helpMenuNode.margin_right, (-100 if helpMenuIsOpened else 0), 0.5, 
				Tween.TRANS_LINEAR, Tween.EASE_OUT)
		tween1.start()
		tween2.start()
		
		yield(tween2, "tween_completed")
		tween2.queue_free()
		tween2.queue_free()
		
		helpMenuIsOpened = not helpMenuIsOpened
		helpMenuToggleInProcess = false


func _input(event):
	if event.is_action_pressed("ui_help") and not gameEnded:
		toogle_help_menu()


func alive_challenge_failed():
	isAlive = false
	helpMenuSecretLabelNode.text = ".." + secretSpeedrunPart if not timeOver else ""


func _on_SpeedrunTimer_timeout():
	timeOver = true
	helpMenuSecretLabelNode.text = ".." + secretAlivePart if isAlive else ""


func end_the_game():
	gameEnded = true
	
	speedrunTimerNode.stop()
	if helpMenuIsOpened:
		toogle_help_menu(true)
	
	if isAlive or not timeOver:
		endScreenLabelNode.text = ("keeptheear" if isAlive else "") + ("thalive" if not timeOver else "") + ".........."
	else:
		endScreenLabelNode.text = "the end..?" + "??????????"
	
	endScreenTweenNode.interpolate_property(endScreenNode, "modulate", Color(1,1,1,0), Color(1,1,1,1), 6.75, Tween.TRANS_LINEAR)
	endScreenTweenNode.start()
	
	yield(endScreenTweenNode,"tween_completed")
	
	endScreenTextTweenNode.interpolate_property(endScreenLabelNode, "percent_visible", 0, 1, 10, Tween.TRANS_LINEAR)
	endScreenTextTweenNode.start()
	yield(endScreenTextTweenNode, "tween_completed")
	
	logoTweenNode.interpolate_property(logoNode, "modulate", logoNode.modulate, Color(1,1,1,1), 30, Tween.TRANS_LINEAR)
	logoTweenNode.start()
	yield(logoTweenNode, "tween_completed")
	get_tree().reload_current_scene()
