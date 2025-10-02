# AudioManager.gd - 支持WAV格式的音频管理器
extends Node

# --- 成员变量 ---
var music_player: AudioStreamPlayer
var sound_players: Array = []
const MAX_SOUNDS := 8

# 音效冷却时间记录
var last_play_times := {}
const DEFAULT_COOLDOWN := 0.1  # 秒

# --- 初始化 ---
func _ready():
	# 避免重复初始化（如果作为 AutoLoad 单例）
	if music_player:
		return
	
	# 创建音乐播放器
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	
	# 创建音效播放器池
	for i in range(MAX_SOUNDS):
		var player := AudioStreamPlayer.new()
		add_child(player)
		sound_players.append(player)
	
	print("🎵 音频管理器初始化完成 - 支持WAV格式")


# --- 播放背景音乐 ---
func play_music(music_path: String, loop: bool = true, volume: float = -10.0) -> void:
	var music: AudioStream = load(music_path)
	if music:
		music_player.stream = music
		
		# Godot 4 的循环设置
		if music.has_method("set_loop"):
			music.set_loop(loop)
		elif "loop" in music:
			music.loop = loop
		
		music_player.volume_db = volume
		music_player.play()
		print("▶️ 正在播放音乐: ", music_path)
	else:
		push_error("❌ 无法加载音乐文件: " + music_path)


# --- 播放音效（带冷却） ---
func play_sound(sound_param, volume: float = 0.0, cooldown: float = DEFAULT_COOLDOWN) -> bool:
	var sound: AudioStream
	if sound_param is String:
		sound = load("res://resources/sounds/small_splash1.mp3")
	elif sound_param is AudioStream:
		sound = sound_param
	else:
		return false
	for player in sound_players:
		if not player.playing:
			player.stream = sound
			player.volume_db = volume
			player.play()
			return true
	
	print("⚠️ 所有音效播放器都在使用中")
	return false


# --- 保证同一音效唯一播放 ---
func play_unique_sound(sound_param, volume: float = 0.0) -> bool:
	var sound: AudioStream
	
	if sound_param is String:
		sound = load(sound_param)
	elif sound_param is AudioStream:
		sound = sound_param
	else:
		return false
	
	# 如果该音效已经在播放，重置播放
	for player in sound_players:
		if player.playing and player.stream == sound:
			player.stop()
			player.play()
			print("♻️ 重置音效播放: ", str(sound_param))
			return true
	
	# 否则正常播放
	return play_sound(sound_param, volume)


# --- 音乐控制 ---
func stop_music():
	if music_player:
		music_player.stop()

func set_music_volume(volume: float):
	if music_player:
		music_player.volume_db = volume

func set_music_loop(should_loop: bool):
	if music_player and music_player.stream:
		if music_player.stream.has_method("set_loop"):
			music_player.stream.set_loop(should_loop)
		elif "loop" in music_player.stream:
			music_player.stream.loop = should_loop
