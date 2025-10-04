extends Resource
class_name LevelConfig


# 每种鱼对应的 FishData (.tres) 列表
@export var fish_data_list: Array[Resource] = []

# 每种鱼对应的权重
@export var spawn_weights: Array[float] = []

# 最大鱼数量
@export var max_fish_count: int = 20

# 刷新间隔
@export var spawn_interval: float = 2.0

# 刷鱼区域
@export var spawn_area: Rect2 = Rect2(0,0,1152,648)

# --- 多个鱼 ---
@export var fish_scenes: Array[PackedScene] = []          # 每种鱼的场景
