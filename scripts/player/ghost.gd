extends Node2D

@export var fade_time: float = 0.3
@onready var sprite: Sprite2D = $Sprite2D

var lifetime: float

func _ready():
	lifetime = fade_time
	modulate.a = 0.6

func _process(delta):
	lifetime -= delta
	modulate.a = max(0, lifetime / fade_time) * 0.6
	if lifetime <= 0:
		queue_free()

func set_texture(tex: Texture2D):
	sprite.texture = tex
