extends Resource
class_name FishData

# --- 基础属性 ---
@export var fish_name: String = "小鱼"
@export var speed: float = 50.0
@export var flee_speed: float = 120.0
@export var wander_range: float = 100.0
@export var vision_range: float = 80.0
@export var value: int = 10

# --- 捕捉相关 ---
@export var strength: float = 100.0        # 鱼体力上限（决定捕捉难度）
@export var recovery: float = 2.0          # 每秒恢复体力
@export var duration: float = 8.0          # 挣扎总时长
# --- 特殊效果 ---
@export_enum("None", "Spike", "Ink", "Electric", "Bite")
var effect: String = "None"           # 鱼的特殊效果类型

@export var effect_value: float = 0.0     # 效果数值，比如伤害、减速值
@export var effect_interval: float = 0.0  # 效果触发间隔