# FishStruggle.gd
extends Node

class_name FishStruggle

# 外部配置
var struggle_duration: float = 5.0       # 初始挣扎时间
var struggle_force: float = 100.0        # 初始挣扎力（移动幅度）
var escape_strength_factor: float = 150.0 # 用于计算逃脱概率
var fish_strength: float = 50.0          # 鱼本身力量，用于逃脱判定

# 内部状态
var is_struggling: bool = false
var _current_time: float = 0.0
var _current_force: float = 0.0

# 音效池（外部预加载）
var struggle_sounds: Array = []

# 信号
signal escaped
func setup(fish_data: FishData) -> void:
    struggle_duration = fish_data.duration
    fish_strength = fish_data.strength
# 初始化抓捕状态
func start_struggle(sounds: Array) -> void:
    struggle_sounds = sounds
    is_struggling = true

# 每帧更新挣扎
func update(delta: float) -> Vector2:
    if not is_struggling:
        return Vector2.ZERO

    _current_time -= delta
    var move_vector = Vector2.ZERO

    # 随机抽动模拟挣扎
    if randf() < 0.2:
        move_vector = Vector2(randf_range(-1,1), randf_range(-1,1)).normalized() * _current_force
        _play_struggle_sound()

    # 衰减挣扎力
    _current_force = lerp(_current_force, 0.0, 0.05)

    # 检查逃脱
    if randf() < _escape_chance_per_second(delta):
        is_struggling = false
        emit_signal("escaped")
        return move_vector

    # 结束挣扎
    if _current_time <= 0.0 or _current_force <= 5.0:
        is_struggling = false

    return move_vector

# 逃脱概率
func _escape_chance_per_second(delta: float) -> float:
    return clamp((fish_strength / escape_strength_factor) * delta, 0.01, 0.5)

# 播放音效
func _play_struggle_sound() -> void:
    if struggle_sounds.size() == 0:
        return
    var sound = struggle_sounds[randi() % struggle_sounds.size()]
    if Engine.has_singleton("SoundManager"):
        Engine.get_singleton("SoundManager").play_sound(sound)

# 辅助函数
func randf_range(a: float, b: float) -> float:
    return lerp(a, b, randf())
    
func _is_struggling() -> bool:
    return is_struggling