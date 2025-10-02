extends Resource
class_name ToolData

@export var tool_name: String = "徒手"
@export var tool_texture: Texture2D
@export var success_bonus: float = 0.0  # 捕捉成功率加成
@export var catch_range_multiplier: float = 1.0  # 范围倍率
@export var catch_sound: AudioStream