extends Node2D
class_name FishManager

# --- 关卡配置 ---
@export var level_config: LevelConfig  # Inspector 拖入 Level1Config.tres

# --- 内部状态 ---
var _current_fish_count: int = 0
var _spawn_timer: float = 0.0

# --- 音效资源 ---
@export var struggle_sounds: Array = []
@export var swim_sounds: Array = []
@export var skill_sounds: Array = []

func _ready():
	if level_config == null:
		push_error("LevelConfig not assigned!")
		return
	
	_spawn_timer = level_config.spawn_interval
	
	for i in range(min(5, level_config.max_fish_count)):
		_spawn_fish()


func _process(delta):
	if level_config == null:
		return
	
	if _current_fish_count < level_config.max_fish_count:
		_spawn_timer -= delta
		if _spawn_timer <= 0:
			_spawn_fish()
			_spawn_timer = level_config.spawn_interval


# --- 刷鱼 ---
func _spawn_fish():
	if level_config == null:
		push_error("LevelConfig not assigned!")
		return
	
	var scenes = level_config.fish_scenes
	var datas = level_config.fish_data_list
	var weights = level_config.spawn_weights

	# 安全检查
	if scenes.size() == 0 or datas.size() == 0 or weights.size() == 0:
		push_error("LevelConfig arrays are empty!")
		return
	
	if scenes.size() != datas.size() or scenes.size() != weights.size():
		push_error("LevelConfig arrays length mismatch!")
		return
	
	# 根据权重选择索引
	var idx = _choose_fish_by_weight(weights)
	var scene: PackedScene = scenes[idx]
	if scene == null:
		push_error("PackedScene at index %d is null" % idx)
		return
	
	var new_fish = scene.instantiate()
	add_child(new_fish)
	new_fish.global_position = Vector2(
		randf_range(level_config.spawn_area.position.x, level_config.spawn_area.position.x + level_config.spawn_area.size.x),
		randf_range(level_config.spawn_area.position.y, level_config.spawn_area.position.y + level_config.spawn_area.size.y)
	)
	
	# 赋值 FishData
	if datas[idx] != null:
		new_fish.fish_data = datas[idx].duplicate(true)
	else:
		push_warning("No FishData at index %d" % idx)
	
	# 初始化鱼模块
	_init_fish_systems(new_fish)
	
	_current_fish_count += 1
	new_fish.tree_exiting.connect(Callable(self, "_on_fish_removed"))


# --- 权重选择 ---
func _choose_fish_by_weight(weights: Array) -> int:
	var total_weight = 0.0
	for w in weights:
		total_weight += float(w)
	if total_weight <= 0.0:
		return 0
	
	var r = randf() * total_weight
	var accum = 0.0
	for i in range(weights.size()):
		accum += float(weights[i])
		if r <= accum:
			return i
	return weights.size() - 1


# --- 初始化鱼模块 ---
func _init_fish_systems(fish_node: Node):
	if fish_node == null or fish_node.fish_data == null:
		push_error("Fish prefab missing fish_data!")
		return
	
	# 体力
	var stamina_system = FishStamina.new()
	stamina_system.setup(fish_node.fish_data)
	fish_node.stamina_system = stamina_system
	
	# 挣扎
	var struggle_system = FishStruggle.new()
	fish_node.struggle_system = struggle_system
	
	# 技能
	var skill_system = FishSkillSystem.new()
	skill_system.setup(fish_node.fish_data)
	fish_node.skill_system = skill_system
	
	# 音效
	var sound_system = FishSound.new()
	sound_system.init_swim_sounds(swim_sounds)
	sound_system.init_skill_sounds(skill_sounds)
	sound_system.setup(struggle_sounds)
	fish_node.sound_system = sound_system


# --- 删除鱼 ---
func _on_fish_removed():
	_current_fish_count = max(_current_fish_count - 1, 0)


# --- 工具函数 ---
func randf_range(a: float, b: float) -> float:
	return lerp(a, b, randf())
