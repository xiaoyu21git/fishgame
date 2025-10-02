extends Node2D
@onready var bgm_player = $BGMPlayer

func _ready():
	SoundManager.play_music("res://resources/sounds/Beach.ogg")
	#SoundManager.set_music_loop(true)

# func toggle_music():
	# if bgm_player.playing:
	#     bgm_player.stop()
	# else:
	#     bgm_player.play()
