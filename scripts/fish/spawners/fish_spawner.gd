extends Node2D
class_name FishSpawner

@export var level_config: LevelConfig
@export var debug: bool = true

var _current_fish_count: int = 0
var _spawn_timer: float = 0.0

func _ready():
	if not _check_level_config():
		return

	randomize()
	_spawn_timer = level_config.spawn_interval

	for i in range(int(level_config.max_fish_count / 2)):
		_spawn_fish()


func _process(delta):
	if _current_fish_count < level_config.max_fish_count:
		_spawn_timer -= delta
		if _spawn_timer <= 0:
			_spawn_fish()
			_spawn_timer = level_config.spawn_interval


func _spawn_fish():
	var scenes = level_config.fish_scenes
	var datas = level_config.fish_data_list
	var weights = level_config.spawn_weights

	if scenes.size() == 0 or datas.size() == 0 or weights.size() == 0:
		push_error("FishSpawner: LevelConfig arrays are empty")
		return

	if scenes.size() != datas.size() or scenes.size() != weights.size():
		push_error("FishSpawner: LevelConfig arrays length mismatch!")
		return

	var idx = _choose_fish_by_weight(weights)
	_instantiate_fish_at_index(idx)


func _instantiate_fish_at_index(idx: int) -> void:
	var scene: PackedScene = level_config.fish_scenes[idx]
	if scene == null:
		push_error("PackedScene at index %d is null" % idx)
		return

	var new_fish = scene.instantiate()
	add_child(new_fish)
	if not new_fish.is_in_group("fish"):
		new_fish.add_to_group("fish")

	var area: Rect2 = level_config.spawn_area
	new_fish.global_position = Vector2(
		randf_range(area.position.x, area.position.x + area.size.x),
		randf_range(area.position.y, area.position.y + area.size.y)
	)

	# 赋值 FishData
	var data_res = level_config.fish_data_list[idx].duplicate(true)
	new_fish.fish_data = data_res

	_init_fish_systems(new_fish)
	new_fish.tree_exiting.connect(Callable(self, "_on_fish_removed"))
	_current_fish_count += 1
	if debug:
		print("[FishSpawner] spawned fish idx=", idx, " current_count=", _current_fish_count)


func _init_fish_systems(fish_node: Node) -> void:
	if fish_node.fish_data == null:
		if debug:
			push_warning("fish_node has no fish_data; skipping subsystems.")
		return

	var stamina = FishStamina.new()
	stamina.setup(fish_node.fish_data)
	fish_node.stamina_system = stamina

	var struggle = FishStruggle.new()
	struggle.setup(fish_node.fish_data)
	fish_node.struggle_system = struggle

	var skill = FishSkillSystem.new()
	skill.setup(fish_node.fish_data)
	fish_node.skill_system = skill

	var sound = FishSound.new()
	sound.setup([])
	fish_node.sound_system = sound


func _on_fish_removed() -> void:
	_current_fish_count = max(_current_fish_count - 1, 0)
	if debug:
		print("[FishSpawner] fish removed. current_count=", _current_fish_count)


func randf_range(a: float, b: float) -> float:
	return lerp(a, b, randf())


func _choose_fish_by_weight(weights: Array) -> int:
	var total = 0.0
	for w in weights:
		total += float(w)
	if total <= 0:
		return 0

	var r = randf() * total
	var accum = 0.0
	for i in range(weights.size()):
		accum += float(weights[i])
		if r <= accum:
			return i
	return weights.size() - 1


func _check_level_config() -> bool:
	if level_config == null:
		push_error("LevelConfig is null")
		return false
	if level_config.fish_scenes == null or level_config.fish_data_list == null or level_config.spawn_weights == null:
		push_error("LevelConfig arrays are null")
		return false
	var n = level_config.fish_scenes.size()
	if n == 0 or n != level_config.fish_data_list.size() or n != level_config.spawn_weights.size():
		push_error("LevelConfig arrays empty or length mismatch")
		return false
	if debug:
		print("[FishSpawner] LevelConfig OK, fish types=", n)
	return true
