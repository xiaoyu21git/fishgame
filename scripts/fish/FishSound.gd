# FishSound.gd
extends Node
class_name FishSound

# 音效池
var struggle_sounds: Array = []
var swim_sounds: Array = []
var skill_sounds: Array = []

# === 初始化音效池 ===
func setup(struggle: Array = [], swim: Array = [], skill: Array = []) -> void:
    """
    统一初始化各类音效池
    """
    struggle_sounds = struggle.duplicate()
    swim_sounds = swim.duplicate()
    skill_sounds = skill.duplicate()

# 分别初始化（可选）
func init_struggle_sounds(sounds: Array) -> void:
    struggle_sounds = sounds.duplicate()

func init_swim_sounds(sounds: Array) -> void:
    swim_sounds = sounds.duplicate()

func init_skill_sounds(sounds: Array) -> void:
    skill_sounds = sounds.duplicate()

# === 播放音效接口 ===
func play_struggle_sound() -> void:
    _play_random_from_pool(struggle_sounds)

func play_swim_sound() -> void:
    _play_random_from_pool(swim_sounds)

func play_skill_sound() -> void:
    _play_random_from_pool(skill_sounds)

# === 内部通用方法：从音效池随机播放 ===
func _play_random_from_pool(pool: Array) -> void:
    if pool.size() == 0:
        return
    var idx = randi() % pool.size()
    var sound = pool[idx]
    # 假设 SoundManager 是全局单例，用于播放音效
    if Engine.has_singleton("SoundManager"):
        Engine.get_singleton("SoundManager").play_sound(sound)

