extends Node2D

@export var fish_scene: PackedScene
@export var spawn_area: Rect2 = Rect2(0, 0, 1152, 648)
@export var max_fish_count: int = 20
@export var spawn_interval: float = 2.0

var _current_fish_count: int = 0
var _spawn_timer: float = 0.0

func _ready():
	for i in range(5):
		_spawn_fish()

func _process(delta):
	if _current_fish_count < max_fish_count:
		_spawn_timer -= delta
		if _spawn_timer <= 0:
			_spawn_fish()
			_spawn_timer = spawn_interval

func _spawn_fish():
	if fish_scene == null:
		push_error("Fish scene is not assigned!")
		return
	
	var new_fish = fish_scene.instantiate()
	add_child(new_fish)
	
	var spawn_pos = Vector2(
		randf_range(spawn_area.position.x, spawn_area.end.x),
		randf_range(spawn_area.position.y, spawn_area.end.y)
	)
	new_fish.global_position = spawn_pos
	
	_current_fish_count += 1
	# 连接鱼的删除信号（如果需要）
	# new_fish.tree_exiting.connect(_on_fish_removed)

func _on_fish_removed():
	_current_fish_count -= 1
