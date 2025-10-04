extends CharacterBody2D
class_name Player

# 子系统引用
@onready var movement: PlayerMovement = $Movement
@onready var stamina: PlayerStamina = $Stamina
@onready var catcher: PlayerCatch = $Catch
@onready var tools: PlayerTools = $PlayerTools
@onready var anim: PlayerAnimation = $Animation
@onready var audio: PlayerAudio = $PlayerAudio

func _ready():
	# 初始化各子系统
	movement.init(self, $Stamina,$Sprite2D)
	catcher.init(self, tools, audio)
	tools.init(self, anim, audio)

func _physics_process(delta):
	stamina._process_stamina(delta)
	movement._process_movement(delta)
	catcher._process_catch(delta)
	tools._process_tools(delta)
